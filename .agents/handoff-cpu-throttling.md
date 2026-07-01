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

### Architecture (from original plan)

- **Detection:** Poll every 8s: load > 4.0 / temp > 88°C / freq-ratio < 65% for 2 consecutive polls
- **Process resolver:** X-window-title → cmdline heuristics → parent-walk → comm
- **Actions:** Kill / Force-Kill / Renice-to-idle / Run-on-@mbp / Open-htop / Snooze
- **Service:** systemd user unit, import DISPLAY/XAUTHORITY in i3

### Open Decisions (need user input)

1. **rofi vs yad** for the popup dialog
   - rofi: keyboard-only, type-to-filter, matches i3/dmenu muscle memory
   - yad: more dialog-like, Alt+letter mnemonics

2. **tmux** for "run on @mbp" terminal rebinding
   - tmux: true same-pane reuse via `tmux send-keys`
   - No tmux: spawn fresh alacritty window with reconstructed command

### Files to create

- `private_dot_local/bin/executable_cpu-watchdog` — main daemon
- `private_dot_config/systemd/user/cpu-watchdog.service` — systemd unit
- Update `run_onchange_after_enable-systemd-units.sh.tmpl` — add cpu-watchdog
- Update `private_dot_config/i3/config` — add `import-environment DISPLAY XAUTHORITY`
- Add fish abbrs: `cpustat` for quick load/temp/freq check

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
