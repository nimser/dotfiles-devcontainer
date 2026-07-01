# CPU Throttling Solution - Handoff Document

## Overview

Project to solve CPU throttling on a Debian trixie ThinkPad (i5 8250U, Intel UHD 620, i3 WM, nodm) using a multi-pronged approach: hardware acceleration, remote task offload to M1 Mac, and a CPU watchdog daemon.

## Completed Work

### Component 3: Intel VA-API + Browser GPU Acceleration ✅ DONE

**What was achieved:**

- Full Intel GPU stack unlocked on Kaby Lake (UHD 620)
- Video decode: Hardware accelerated (H264/VP9/VP8/HEVC via iHD)
- Canvas/Rasterization: Hardware accelerated
- WebGL/WebGPU: Hardware accelerated via Vulkan
- GL_RENDERER: Intel UHD 620 via Vulkan 1.4.305

**Key technical decisions:**

1. `--use-angle=vulkan` — routes ANGLE through Intel ANV Vulkan driver
   - `--use-gl=desktop` removed in Chromium 130+ (maps to gl=none)
   - `--use-angle=gl` falls back to llvmpipe (DRI3 unavailable on this X setup)
   - Vulkan works correctly

2. Brave flags file (`~/.config/brave-flags.conf`) is **not read** by Debian's Brave `.deb` launcher (unlike Arch's chromium package)
   - Created wrapper at `~/.local/bin/brave-browser` that reads the flags file and prepends them
   - Wrapper sits earlier in PATH, so all launchers (i3, dmenu, $BROWSER) hit it first

3. All Brave shims updated to route through wrapper:
   - `main` / `shop` — firejail without --private, call `brave-browser`
   - `guoyu` — no firejail, calls `brave-browser`
   - `brave-browser0` — firejail with --private, whitelists wrapper and flags file

**Files created/modified:**

- `private_dot_config/chromium-flags.conf` — single shared GPU flags file (`brave-flags.conf` deleted, DRY)
- `private_dot_local/bin/executable_chromium-launch` (new) — shared flags injector for all Chromium-based browsers
- `private_dot_local/bin/executable_brave-browser` (new) — one-liner shim → chromium-launch
- `private_dot_local/bin/executable_brave-browser0` (updated) — firejail whitelist → chromium-flags.conf + chromium-launch
- `private_dot_local/bin/executable_main` (updated) — use `brave-browser` not `brave-browser-stable`
- `private_dot_local/bin/executable_guoyu` (updated) — drop absolute path
- `dot_xsessionrc` (updated) — export LIBVA_DRIVER_NAME=iHD

**Note — Google Chrome (nix) abandoned:**
Attempted to extend flags pipeline to `google-chrome-stable` (nix). Blocked by:

1. nix closure doesn't include host Vulkan ICDs / `libigdgmm.so.12` → `--use-angle=vulkan` fails with `vkCreateInstance: Found no drivers`.
2. `/etc/fish/conf.d/nix.fish` force-prepends nix to `fish_user_paths` (global scope), making `~/.local/bin` shimming unreliable in fish.
   Fix requires `nixGLIntel google-chrome-stable …`. Deferred — Brave only for now.

**Installed on host (Debian):**

- `vainfo` — VA-API verification
- `intel-gpu-tools` — `intel_gpu_top` for GPU engine utilization monitoring
- `intel-media-driver` (already present) — iHD VA-API backend
- `mesa` stack (already present) — iris_dri.so GL driver

**Committed and pushed** to chezmoi repo.

**Remaining limitations (acceptable, don't cause throttling):**

- Compositing: Software only (Chromium blocklist override, won't enable despite flags)
- Video Encode: Software only (webcam/conferencing only, not needed for throttling fix)
- These are Gen9.5 Intel GPU limitations in Chromium's blocklist

---

## Next: Component 1 — CPU Watchdog Daemon

### Status: ✅ Mostly Complete (2 known issues)

**Implemented:**

- Polling daemon with load/temp/freq thresholds (8s interval, 2-strike trigger)
- Rofi dialog with single-key actions (k=kill, f=force-kill, r=renice, h=htop, s=snooze, d=dismiss)
- Process resolver: xdotool parent-walk to find window title
- tmux-aware terminal launcher (opens htop in tmux if available)
- Fish integration: `cpustat` function + `cpuw-{start,stop,log,st,test}` abbreviations
- Systemd user service with bash -lc wrapper for PATH

**Files:**

- `private_dot_local/bin/executable_cpu-watchdog` (daemon)
- `private_dot_local/bin/executable_cpu-alert-copy` (xclip helper)
- `private_dot_config/systemd/user/cpu-watchdog.service`
- `private_dot_config/i3/config` (for_window rules, Mod+Alt+r focus binding)
- `private_dot_config/nixpkgs/config.nix` (rofi, xdotool, xclip)
- `private_dot_config/fish/functions/cpustat.fish`
- `private_dot_config/fish/conf.d/abbrevs.fish` (cpuw-* abbrs)

**Related infra:**

- `dot_bashrc`: removed `exec fish` (broke bash scripts)
- `private_dot_config/tmux/tmux.conf.tmpl`: basic config, Catppuccin Macchiato, default-shell=fish
- `private_dot_config/i3/config`: Mod+Return → `alacritty -e tmux new-session -A -s main`

**Known issues — RESOLVED:**

1. ~~Rofi dialog not floating~~ ✅ Fixed
2. ~~Rofi stealing focus~~ ✅ Fixed (same root cause as #1)

**Root cause (found via rofi source inspection, `xcb/view.c`):** rofi
hardcodes its own `WM_CLASS` to `instance=rofi, class=Rofi` and its window
title to `"rofi"` / `"rofi - <mode display name>"` (e.g. `"rofi - dmenu"`).
There is **no** command-line flag to override this in current rofi — the
`-name cpu-alert` flag used in `cpu-watchdog`'s `show_dialog()` doesn't
exist (absent from `rofi.1` manpage and source `rofi.c`/`xrmoptions.c`)
and was being silently ignored. Consequently the i3 criteria
`[class="Rofi" title="cpu-alert"]` never matched anything (title is never
`"cpu-alert"`), so **neither** the `floating enable` rule nor the
`no_focus` rule ever fired — same bug, two symptoms.

**Fix applied:**

- `private_dot_config/i3/config`: dropped the bogus `title="cpu-alert"`
  criterion, matching on `[class="Rofi"]` alone for the `bindsym
  $mod+Mod1+r … focus`, `for_window … floating enable, border none`, and
  `no_focus` rules. Safe because rofi is invoked _only_ for cpu-alert in
  this config (app launching uses `dmenu_run`, not rofi).
- `private_dot_local/bin/executable_cpu-watchdog`: removed the dead
  `-name cpu-alert` flag from the `rofi -dmenu` invocation, added a
  comment explaining why.
- Committed to chezmoi repo; **not yet verified on the host** (container
  has no i3/rofi) — run `~/.local/bin/cpu-watchdog --test` on the tpad
  host after `chezmoi apply` and confirm the dialog appears floating,
  top-right anchored, and does not steal focus from the active window.

**Debug commands (if still misbehaving):**

```bash
# Trigger test dialog
~/.local/bin/cpu-watchdog --test

# Check rofi window properties (class/instance/title)
xprop | grep -E 'WM_CLASS|WM_NAME|_NET_WM_WINDOW_TYPE'

# Verify i3 rules matched — check floating flag
i3-msg -t get_tree | jq -r 'recurse(.nodes[]) | select(.window_properties.class=="Rofi") | .floating'
```

---

### Follow-up session — clipboard copy + tab identification

**Reported:** (1) can't select rofi dialog content with the mouse, (2)
alert just said "brave" without saying which tab/page was the culprit.

**Root cause (found via rofi source, `helper.c`/`view.c`):** the
`-on-selection-changed 'cpu-alert-copy "{}"'` hook — clearly added
previously as a workaround for rofi's lack of mouse text-selection in
dmenu mode — used the wrong placeholder token. Rofi substitutes
`{entry}`, not `{}`; the literal string `"{}"` was never replaced, so
the "copy to clipboard" safety net was silently copying the two
characters `{}` on every keypress, never the actual row content. On top
of that, the diagnostic info (window title, process name) only ever
lived in `-mesg`, a static label that was never wired to the copy hook
anyway (and isn't mouse-selectable either). For the "which tab" question:
Chromium/Brave renderer subprocesses don't own X11 windows and don't
expose tab titles/URLs via argv (privacy sandboxing) — the previous
implementation had no way to say more than the owning browser *window's*
title (which reflects the active tab, not necessarily the runaway
background one), and said nothing at all when that resolution failed.

**Fix applied (`private_dot_local/bin/executable_cpu-watchdog`):**

- Fixed the placeholder: `-on-selection-changed 'cpu-alert-copy "{entry}"'`
- `resolve_culprit()` now parses the offending process's `--type=` flag
  (e.g. `renderer`, `gpu-process`, `utility`) to label *what kind* of
  Chromium subprocess is misbehaving, alongside its `comm`
- Diagnostic info moved out of the static `-mesg` header into real,
  selectable dmenu rows (`info_row`, plus `win_row` for the window title
  or an explicit "🫥 no window found — likely a background tab" note when
  resolution fails) — row 0 is pre-selected when the dialog opens, so
  it's auto-copied to PRIMARY+CLIPBOARD with **no keypress needed**
- Added an explicit `[c] Copy details` action (kb-custom-5, `c` key) that
  copies a fuller diagnostic string (pid, comm, type, %cpu, window title,
  cmdline) built from real variables, then re-opens the dialog so the
  user can still pick kill/renice/etc. afterwards
- `-mesg` now only shows the quick-glance load/temp/freq metrics

**Still a known limitation:** true per-tab identification (exact page
title/URL of the runaway renderer, vs. just the owning window/whichever
tab happens to be visible) would require the DevTools protocol or
chrome://process-internals, not just process/window introspection.
Not implemented — out of scope for now.

**Not yet verified on host** — after `chezmoi apply`, run
`~/.local/bin/cpu-watchdog --test`, confirm: dialog opens with the info
row already in your clipboard (try pasting immediately), the emoji rows
render fine in the rofi font, and `[c] Copy details` works.

---

## Not Yet Started

### Component 2 — remrun (M1 offload wrapper)

- Thin dispatcher: `--container` (devpod, default) / `--native` (ssh)
- devpod owns sync/CWD context
- LLM: out of remrun — native Ollama on Mac, LAN endpoint
- Fish abbrs: `@mbp`, `@mbps`, `@mbpsh`, `@mbpst`

### Component 4 — PerfGuard browser extension

- Manifest V3, per-tab toggles
- Freeze animations / throttle RAF / pause videos / kill web fonts
- Load unpacked in Brave

---

## Environment Details

- **Host:** Debian 13 (trixie), kernel 6.12.73
- **CPU:** Intel i5 8250U (Kaby Lake-R), 4c/8t, UHD 620 (Gen9.5)
- **WM:** i3 on X11, nodm auto-login, picom (xrender backend)
- **Shell:** Fish
- **Browser:** Brave (chromium-based), $BROWSER=brave-browser
- **Theme:** Catppuccin Macchiato
- **Displays:** eDP1 (internal 1920x1080) + DP1 (external 2560x1440)
- **Hostname:** tpad (referenced in chezmoi templates)
- **Remote:** MacBook Pro M1 (for offload)
- **chezmoi source:** `/home/vscode/.local/share/chezmoi`
- **chezmoi config:** encryption=age, identities=tpm/yubikeys
