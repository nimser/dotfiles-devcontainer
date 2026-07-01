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
- `private_dot_local/bin/executable_cpu-restore` (undo a renice — see follow-up session 4)
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
implementation had no way to say more than the owning browser _window's_
title (which reflects the active tab, not necessarily the runaway
background one), and said nothing at all when that resolution failed.

**Fix applied (`private_dot_local/bin/executable_cpu-watchdog`):**

- Fixed the placeholder: `-on-selection-changed 'cpu-alert-copy "{entry}"'`
- `resolve_culprit()` now parses the offending process's `--type=` flag
  (e.g. `renderer`, `gpu-process`, `utility`) to label _what kind_ of
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

---

### Follow-up session 2 — feedback on the above fix

**Reported:** (1) auto-copy is dangerous, it clobbers whatever the user
had on the clipboard at that moment; (2) the shown title looks like the
currently _focused_ window, not necessarily the culprit; (3) the dialog
still doesn't say _why_ it fired — load, temp, or freq.

**Fix applied (`private_dot_local/bin/executable_cpu-watchdog`):**

1. **Removed `-on-selection-changed` entirely.** No more automatic
   clipboard writes on open or arrow-key navigation. Copying is now
   100% explicit via the `[c] Copy details` row/key — the only time
   your clipboard is touched is when you deliberately ask for it.
2. **Two real bugs found in the window-title resolution:**
   - There was a "last resort" fallback that showed _whatever window is
     currently active_ when the culprit's own window couldn't be
     resolved — i.e. a window totally unrelated to the culprit process,
     presented as if it were relevant. Removed; an unresolved title is
     now just left blank (with an explicit "no window found" row)
     rather than guessing wrong.
   - Even when correctly resolved, a browser window's title reflects
     whichever tab is currently _visible_, not necessarily the tab whose
     renderer process is actually burning CPU in the background — there
     is no X11-level way to attribute a renderer PID to a specific tab
     (Chromium deliberately doesn't expose per-tab info via argv/process
     introspection, for privacy/site-isolation reasons). The title is
     now explicitly labeled `possibly: <title> (active tab — may not be
     the culprit)`, and a `🪟×N multiple windows open` row appears when
     the owning process has more than one window (further reducing
     confidence in the guess).
   - **New approach instead of guessing:** added a `[t] Open browser
     Task Manager` action (only shown for brave/chrome/chromium `comm`)
     that sends Chromium's native `Shift+Escape` shortcut to the
     resolved browser window via `xdotool key --window`. This opens the
     browser's own built-in Task Manager, which _does_ show accurate
     per-tab/extension CPU% — delegating the one thing we structurally
     can't determine from outside the browser to the one tool that can.
     Other DevTools-protocol-based approaches (querying `--remote-
     debugging-port`, `chrome://process-internals`) were considered but
     rejected: they'd require enabling a debugging port permanently
     (security/attack-surface tradeoff) for a rarely-used diagnostic.
3. **Trigger cause was being silently lost.** `show_dialog` previously
   re-sampled load/temp/freq itself when building the dialog, instead of
   using the values that actually caused the 2-strike trigger in the
   polling loop. `freq` in particular is extremely volatile under DVFS
   and can bounce back to normal within milliseconds — so by the time
   the dialog re-sampled it, the "!" marker could vanish entirely, making
   the alert look like it fired for no reason. Fix: the main loop now
   tracks the **peak/worst** load, temp, and freq observed across the
   whole strike streak (`peak_load`/`peak_temp`/`peak_freq`, reset
   whenever the streak breaks) and passes those into `show_dialog`
   instead of re-sampling. The dialog's first line now explicitly reads
   `⚠ triggered by: load, freq` (etc.) so the cause is unambiguous, in
   addition to the existing `!`-suffixed metric markers.

**Not yet verified on host** — after `chezmoi apply`, run
`~/.local/bin/cpu-watchdog --test` and confirm: clipboard is untouched
unless you press `[c]`, the `possibly:`/`no window found`/`multiple
windows` wording reads sensibly, `[t]` actually raises Brave's Task
Manager, and the `⚠ triggered by: …` line appears and matches the values
below it.

---

### Follow-up session 3 — freq-based trigger removed, self-detection bug fixed

**Reported:** a real alert fired with `cause: freq` alone (`load 1.68`,
`temp 53°C`, `freq 23%`) while the machine was doing essentially
nothing — and the "culprit" it blamed was `ps` itself at `200%`.

**Root cause #1 — `freq_bad` was fundamentally miscalibrated.**
`get_freq_pct()` compares live `scaling_cur_freq` against
`cpuinfo_max_freq`, which on Intel CPUs is the **Turbo Boost ceiling**
(~3.4 GHz here), not a sustained/normal operating point. Idle or
light-load clocks on this chip naturally sit around 400–800 MHz — i.e.
**well under any reasonable percentage of turbo max, all the time,
regardless of whether anything is wrong.** The check also had no
correlation with actual demand (it was OR'd independently alongside
`load_bad`/`temp_bad`), so it could not distinguish "CPU is being held
back from work it wants to do" (real throttling — power/thermal
capping under load) from "CPU has nothing to do and is correctly
clocking down to save power" (normal idle behavior). Given this
laptop's load average was ~1.7 out of 8 logical CPUs at the time, this
was almost certainly the latter — a false positive baked into the
metric's design, not a fluke.

A correct version of this check would require correlating low frequency
with a real demand signal (e.g. recent CPU busy% from `/proc/stat`
deltas, not the laggier 1-minute load average) — otherwise "low freq"
is meaningless on its own. Given the added complexity for a fairly
niche failure mode (PL1/PL2 power-budget throttling without high temp,
rare on this hardware), **the decision was to remove it entirely**
rather than half-fix it.

**Fix applied (`private_dot_local/bin/executable_cpu-watchdog`):**

- Removed `FREQ_RATIO_THRESH`/`CPU_WD_FREQ_RATIO`, `get_freq_pct()`,
  and every `freq`/`peak_freq` reference from the trigger logic,
  `show_dialog`, the `--test` path, and log messages. The watchdog now
  triggers on `load` and `temp` only — both of which are unambiguous
  ("bad" always means "too high", no idle-state ambiguity).
- The `[c] Copy details` string, `-mesg` header, and `⚠ triggered by: …`
  line all updated accordingly (no more `freq NN%` fields).

**Root cause #2 — `resolve_culprit()` could catch itself.** The `ps`
pipeline that samples "top CPU process" only excluded the watchdog
script's own `$$`, not the transient `ps`/`awk` processes it was itself
spawning to do that sampling. A freshly-spawned, very-short-lived
process can report a wildly inflated `%CPU` (computed as
`cputime / process_age`, and age was near-zero), so `ps` occasionally
"caught itself" mid-sample and got blamed as the culprit — exactly what
produced the bogus `pid … ps 200%` report.

**Fix applied:** rather than a narrow name-blocklist (which only
covers `ps`/`awk` and would miss any other transient helper), the
`ps` pipeline in `resolve_culprit()` now also samples `etimes`
(elapsed process age in seconds) and excludes anything under 2s old:
`ps -eo pid,ppid,comm,%cpu,etimes ... | awk -v me=$$ '$1 != me && $5 >= 2
{print $1, $2, $3, $4}'`. A real, sustained culprit will already be
several seconds old by the time the 2-strike/8s-poll trigger fires, so
this is safe and strictly more general than blocking specific command
names. Verified locally: `resolve_culprit` no longer picks up its own
`ps`/`awk` pipeline.

**Not yet verified on host** — after `chezmoi apply`, confirm
`cpu-watchdog --test` no longer offers `freq` as a possible cause, and
that a deliberately-induced high-load scenario (e.g. `yes > /dev/null &`
x4) still triggers correctly on `load`/`temp` alone.

---

### Follow-up session 4 — per-alert "suggested action" + quick un-renice

**Reported:** the dialog offers a flat menu of equally-weighted actions
with no steer for what to actually try first; also, once you `[r]`
renice something to idle, how do you get it back to full speed fast if
you suddenly need it?

**Design decision — one bold, opinionated suggestion per alert, not a
per-program table.** Rather than hand-maintaining a growing lookup of
"if comm == X, suggest Y" for every program that might ever trigger an
alert, the suggestion is keyed off the one structural distinction that
actually changes the right first move: is the culprit a browser or not?

- **Browser** (`comm` matches `*brave*|*chrome*|*chromium*`): suggest
  **`[t] open Task Manager`**. Killing/renicing the browser's _process_
  is blunt — the real fix is almost always ending one runaway tab/
  extension, and Chromium's own Task Manager is the only place that can
  accurately attribute CPU to a specific tab (see follow-up session 2 —
  renderer PIDs don't expose tab identity at the OS level).
- **Everything else**: suggest **`[r] renice to idle`** — reversible,
  doesn't kill/lose work, and immediately stops the process from
  starving everything else without deciding anything irreversible.

**Fix applied (`private_dot_local/bin/executable_cpu-watchdog`):**

- Added a `suggest_row`, rendered in **bold** via a new `-markup-rows`
  rofi flag + Pango `<b>...</b>` tags, inserted right after the
  info/window rows and before the action list so it's the first thing
  the eye lands on.
- Enabling `-markup-rows` means _every_ row is now parsed as Pango, so
  any interpolated text that can contain `&`/`<`/`>` (window titles —
  page titles routinely contain these) had to be escaped first or
  rendering would break. Added a `pango_esc()` helper and routed
  `comm`/`ptype`/`win_title` through it before building `info_row` and
  `win_row`. Raw (unescaped) values are still used everywhere else
  (logs, clipboard, xdotool calls).

**Follow-up question: how do you easily renice a process back to full
priority if you realize you need it fast again?**

Key fact: Linux's default `RLIMIT_NICE` lets an unprivileged user
freely **raise** their own process's niceness (deprioritize, what `[r]`
does — nice 19) but only lets them **lower it back down to 0** (normal)
without `CAP_SYS_NICE` — going _negative_ (higher-than-normal priority)
requires root. So "undo my renice" is always achievable without sudo;
"give it more than normal priority" is a deliberate `sudo renice -n -5
-p <pid>` call and deliberately out of scope for a quick-fire tool.

**New tool — `private_dot_local/bin/executable_cpu-restore`:**

- Lists the user's currently deprioritized (`nice > 0`) processes via
  `ps -u $(id -u) -o pid,ni,pcpu,comm`, in the same northeast-anchored
  rofi dialog style as cpu-watchdog.
- Selecting one runs `renice -n 0 -p <pid>` (succeeds without sudo per
  the RLIMIT_NICE behavior above) and undoes the matching `ionice -c 3`
  (idle I/O) cpu-watchdog's `[r]` also applies, restoring `ionice -c 2
  -n 4` (best-effort/normal).
- Shows a plain rofi error dialog (`rofi -e`) if nothing is currently
  reniced.
- Bound to `$mod+Mod1+u` in i3 (`private_dot_config/i3/config`) and
  exposed as the `cpuw-restore` fish abbreviation
  (`private_dot_config/fish/conf.d/abbrevs.fish`) for the same
  "instant access" reasoning as the existing `cpuw-*` set.
- The `[r] Renice` case in `cpu-watchdog` now logs a comment pointing
  at `cpu-restore`/`Mod+Alt+u` so the escape hatch is discoverable from
  the code, not just this doc.

**Not yet verified on host** — after `chezmoi apply`: confirm the
`Suggested: ...` row renders in bold (not literal `<b>` tags — would
indicate `-markup-rows` isn't taking effect or rofi version mismatch),
confirm a window title containing `&`/`<`/`>` still renders correctly,
renice something via `[r]`, then confirm `Mod+Alt+u` (or `cpuw-restore`)
lists it and restores it to nice 0 on selection.

---

### Follow-up session 6 — `load` alerts firing too often on light usage

**Reported:** alerts fire too often for the `load` criterion when the
system isn't actually loaded much.

**Root cause.** This laptop has 8 logical CPUs (i5-8250U, 4c/8t), so
the old `LOAD_THRESH=4.0` default was only 50% utilization — easily
and routinely reached by ordinary desktop activity (browser + a couple
of background tasks), not genuine overload. On top of that, load and
temp shared a single `consecutive` strike counter/`TRIGGER_COUNT=2`
(16s at the 8s poll interval), even though load is a far noisier/
spikier signal than temp — a couple of brief load blips alone could
reach the same short trigger count that was really calibrated for the
slower-moving temp signal.

**Fix applied (`private_dot_local/bin/executable_cpu-watchdog`):**

- `LOAD_THRESH` default raised `4.0 → 6.0` (~75% of 8 logical CPUs).
- Strike tracking split into two fully independent streaks/counters
  (`consecutive_load`/`consecutive_temp`, each with their own peak
  tracking), instead of one shared counter. Load now requires its own,
  longer streak: `LOAD_TRIGGER_COUNT` defaults to 4 (32s sustained)
  via `CPU_WD_LOAD_STRIKES`; temp keeps the original, shorter
  `TEMP_TRIGGER_COUNT` default of 2 (16s) via `CPU_WD_TEMP_STRIKES`.
  Both still fall back to the old shared `CPU_WD_STRIKES` env var if
  set, for backwards compatibility.
- The dialog still fires as soon as *either* metric completes its own
  streak — temp-only alerts are unaffected; only load needed to become
  harder to trigger.
- Startup/strike log lines updated to show each metric's own
  threshold/streak progress separately (`load strike N/M`, `temp
  strike N/M`).

**Not yet verified on host** — after `chezmoi apply`, confirm ordinary
light usage (idle-ish browsing) no longer fires `cause: load` alerts,
while a deliberate `yes > /dev/null &` x4+ sustained for ~32s still
triggers one, and that a genuine temp spike still fires at the
original 16s cadence.

---

### Follow-up session 5 — stop hedging with "possibly"

**Reported:** the `🪟 possibly: <title> (active tab — may not be the
culprit)` row is exactly the kind of thing to avoid — either the tool
knows something and states it, or it doesn't and says nothing/asks the
user to check elsewhere. No middle-ground hedge language.

**Fix applied (`private_dot_local/bin/executable_cpu-watchdog`):**

- `resolve_culprit()` now only ever populates `win_title` (the value
  `show_dialog` presents as fact) when it actually is uncontestable
  fact: exactly one window owned by the process (`nwins == 1`) **and**
  the owner isn't a tabbed browser. Browsers are excluded even at
  `nwins == 1` because the _window_ being known doesn't mean the
  _tab_ is — a single window's title still only reflects whichever tab
  is currently visible, which may not be the misbehaving one. Dropped
  the old "prefer the currently-active window" heuristic entirely — it
  was itself a disguised guess whenever there was more than one
  candidate window.
- Added a shared `is_browser_comm()` helper (was previously a duplicated
  inline `case` in `show_dialog`) so "what counts as a browser" can't
  drift between the two functions.
- `show_dialog`'s `win_row` now only ever states measured facts: for
  browsers, the window _count_ (a fact) plus a pointer to `[t]` Task
  Manager for the tab-level answer it can't give; for non-browsers, the
  resolved title when unambiguous, or an honest "can't tell which one"
  when there's more than one window and no title otherwise. The
  `$wid` used to fire the Task Manager shortcut is still an arbitrary
  pick among multiple windows, but that's fine — it's a mechanical
  target for a keystroke, never something displayed as "the" window.
- The `[c] Copy details` clipboard string (`full_info`) follows the same
  rule: title only when it's fact, otherwise (browsers) the known
  window count instead of a guessed tab.

**Not yet verified on host** — after `chezmoi apply`, confirm: a
non-browser app with exactly one window still shows its title, a
browser alert never shows a title/tab guess (only the window count +
`[t]` pointer), and a non-browser app with multiple windows shows the
honest "can't tell which one" row instead of picking one.

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
