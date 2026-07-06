/**
 * pi-claude-swap-auth — Claude Code credential bridge for pi.
 *
 * Overlay extension that re-points the `anthropic` provider's OAuth backend at
 * Claude Code's own credential store (`~/.claude/.credentials.json`, honoring
 * `CLAUDE_CONFIG_DIR`), instead of pi's private `~/.pi/agent/auth.json` copy.
 *
 * Why: `claude-swap` live-swaps Claude Pro/Max accounts by rewriting
 * `.credentials.json`. Because this extension reads that file on *every*
 * `getApiKey()` call, an account swap takes effect on the very next request —
 * no restart, no /login, no re-auth.
 *
 * IMPORTANT — load order: this package must be listed in settings.json
 * `packages` AFTER `@gotgenes/pi-anthropic-auth`. pi's model registry merges
 * provider registrations key-by-key (`upsertRegisteredProvider`), so this
 * overlay replaces only the `oauth` config while keeping pi-anthropic-auth's
 * `streamSimple` transport wrapper (Claude Code billing header + request
 * shaping) fully intact.
 *
 * Refresh semantics mirror Claude Code's: when the file token is expired we
 * refresh against Anthropic's OAuth endpoint and write the rotated tokens back
 * to `.credentials.json` atomically (preserving scopes / subscriptionType /
 * rateLimitTier), so Claude Code, claude-swap, and pi all stay in sync.
 *
 * The `expires` value reported to pi is capped at now+5min. pi only invokes
 * `refreshToken` when *its* stored expiry passes, and a swap can replace the
 * file with a sooner-expiring token behind pi's back; the cap bounds that
 * drift — at least every 5 minutes pi re-enters our refresh path, which
 * re-reads the file (a cheap read when the token is still valid).
 */
import {
  chmodSync,
  mkdirSync,
  readFileSync,
  renameSync,
  unlinkSync,
  writeFileSync,
} from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import type {
  OAuthCredentials,
  OAuthLoginCallbacks,
} from "@earendil-works/pi-ai";
import {
  loginAnthropic,
  refreshAnthropicToken,
} from "@earendil-works/pi-ai/oauth";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const PROVIDER_ID = "anthropic";

/** Report at most this much validity to pi so it re-checks the file often. */
const EXPIRY_CAP_MS = 5 * 60 * 1000;

/** Treat tokens expiring within this margin as already expired. */
const EXPIRY_MARGIN_MS = 60 * 1000;

interface ClaudeOAuthEntry {
  accessToken: string;
  refreshToken?: string;
  expiresAt: number;
  // scopes, subscriptionType, rateLimitTier, … — preserved on write-back.
  [key: string]: unknown;
}

interface ClaudeCredentialsFile {
  file: Record<string, unknown>;
  oauth: ClaudeOAuthEntry;
}

function claudeCredentialsPath(): string {
  const configDir =
    process.env.CLAUDE_CONFIG_DIR?.trim() || join(homedir(), ".claude");
  return join(configDir, ".credentials.json");
}

/**
 * Read and validate `.credentials.json`. Returns null when the file is
 * absent, unparsable, or holds no OAuth entry (e.g. API-key-only setups) —
 * callers then fall back to pi's stored credentials.
 */
function readClaudeCredentials(): ClaudeCredentialsFile | null {
  try {
    const raw = readFileSync(claudeCredentialsPath(), "utf-8");
    const file = JSON.parse(raw) as Record<string, unknown>;
    const oauth = file?.claudeAiOauth as ClaudeOAuthEntry | undefined;
    if (
      oauth &&
      typeof oauth.accessToken === "string" &&
      oauth.accessToken.length > 0 &&
      typeof oauth.expiresAt === "number"
    ) {
      return { file, oauth };
    }
  } catch {
    // Absent or malformed file — treated as "no Claude credentials".
  }
  return null;
}

/**
 * Atomically write rotated tokens back to `.credentials.json`, preserving all
 * sibling keys (scopes, subscriptionType, rateLimitTier) exactly as
 * claude-swap and Claude Code expect. tmp + rename, mode 0600.
 */
function writeClaudeCredentials(
  prior: ClaudeCredentialsFile | null,
  creds: OAuthCredentials,
): void {
  const path = claudeCredentialsPath();
  const next = {
    ...(prior?.file ?? {}),
    claudeAiOauth: {
      ...(prior?.oauth ?? {}),
      accessToken: creds.access,
      refreshToken: creds.refresh,
      expiresAt: creds.expires,
    },
  };
  mkdirSync(dirname(path), { recursive: true, mode: 0o700 });
  const tmp = `${path}.${process.pid}.tmp`;
  try {
    writeFileSync(tmp, JSON.stringify(next), { encoding: "utf-8", mode: 0o600 });
    renameSync(tmp, path);
    chmodSync(path, 0o600);
  } catch (error) {
    try {
      unlinkSync(tmp);
    } catch {
      // best-effort cleanup
    }
    throw error;
  }
}

function capExpiry(expires: number): number {
  return Math.min(expires, Date.now() + EXPIRY_CAP_MS);
}

function toPiCredentials(oauth: ClaudeOAuthEntry): OAuthCredentials {
  return {
    access: oauth.accessToken,
    refresh: oauth.refreshToken ?? "",
    expires: capExpiry(oauth.expiresAt),
  };
}

function isFresh(oauth: ClaudeOAuthEntry): boolean {
  return oauth.expiresAt > Date.now() + EXPIRY_MARGIN_MS;
}

/** Keep the old refresh token when Anthropic omits one from the response. */
function mergeRefreshed(
  base: { refresh: string },
  refreshed: OAuthCredentials,
): OAuthCredentials {
  return {
    ...refreshed,
    refresh:
      typeof refreshed.refresh === "string" &&
      refreshed.refresh.trim().length > 0
        ? refreshed.refresh
        : base.refresh,
  };
}

/**
 * Refresh the token in `.credentials.json` and write it back, returning
 * pi-shaped (expiry-capped) credentials.
 */
async function refreshClaudeFile(
  prior: ClaudeCredentialsFile,
  fallbackRefresh: string,
): Promise<OAuthCredentials> {
  const refreshToken = prior.oauth.refreshToken || fallbackRefresh;
  if (!refreshToken) {
    throw new Error(
      "Claude credentials file has no refresh token; run `claude` (or claude-swap) to re-authenticate.",
    );
  }
  const refreshed = mergeRefreshed(
    { refresh: refreshToken },
    await refreshAnthropicToken(refreshToken),
  );
  writeClaudeCredentials(prior, refreshed);
  return { ...refreshed, expires: capExpiry(refreshed.expires) };
}

const claudeSwapOAuth = {
  name: "Anthropic (Claude Code credentials / claude-swap)",
  usesCallbackServer: true,

  /**
   * "Login" imports the existing Claude Code credentials when present
   * (refreshing them if expired) — zero-login. Only when no credentials file
   * exists do we fall back to the interactive browser OAuth flow, and we then
   * seed `.credentials.json` so claude-swap can manage the result.
   */
  async login(callbacks: OAuthLoginCallbacks): Promise<OAuthCredentials> {
    const prior = readClaudeCredentials();
    if (prior) {
      if (isFresh(prior.oauth)) {
        return toPiCredentials(prior.oauth);
      }
      return refreshClaudeFile(prior, "");
    }
    const creds = await loginAnthropic(callbacks);
    try {
      writeClaudeCredentials(null, creds);
    } catch {
      // Non-fatal: pi still stores the credentials in auth.json.
    }
    return { ...creds, expires: capExpiry(creds.expires) };
  },

  /**
   * Called by pi (under its auth.json lock) when the stored expiry passes.
   * File-first: a still-fresh file token (e.g. refreshed by Claude Code or
   * swapped in by claude-swap) short-circuits without any network call.
   */
  async refreshToken(credentials: OAuthCredentials): Promise<OAuthCredentials> {
    const prior = readClaudeCredentials();
    if (prior) {
      if (isFresh(prior.oauth)) {
        return toPiCredentials(prior.oauth);
      }
      return refreshClaudeFile(prior, credentials.refresh);
    }
    // No Claude credentials file: legacy pi-anthropic-auth behavior.
    const refreshed = mergeRefreshed(
      credentials,
      await refreshAnthropicToken(credentials.refresh),
    );
    return refreshed;
  },

  /**
   * Live token resolution — called per request. Reading the file here is what
   * makes claude-swap swaps take effect on the next request.
   */
  getApiKey(credentials: OAuthCredentials): string {
    return readClaudeCredentials()?.oauth.accessToken ?? credentials.access;
  },
} as const;

export default function (pi: ExtensionAPI): void {
  // Merge-override only the OAuth backend of the `anthropic` provider that
  // @gotgenes/pi-anthropic-auth registered before us (see load-order note in
  // the file header). Its streamSimple transport wrapper stays in place.
  pi.registerProvider(PROVIDER_ID, {
    oauth: claudeSwapOAuth,
  });

  // Seed pi's live AuthStorage from the Claude credentials file on every
  // session start, so a fresh machine (empty auth.json) needs no /login and
  // pi's stored expiry stays loosely aligned with the file.
  pi.on("session_start", async (_event, ctx) => {
    const current = readClaudeCredentials();
    if (!current) {
      return;
    }
    try {
      ctx.modelRegistry.authStorage.set(PROVIDER_ID, {
        type: "oauth",
        ...toPiCredentials(current.oauth),
      });
    } catch {
      // Non-fatal: getApiKey() still reads the file live.
    }
  });
}
