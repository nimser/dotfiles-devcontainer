# Terminal stack: alacritty → tmux → fish / pi

Why this file: the keybinding chain broke four times between 2026-05-25 and
2026-07-01 and each break was re-diagnosed from zero. Every claim below points at
a config file or a commit in the chezmoi repo.

A keypress crosses four layers. A fix at one layer routinely breaks another —
that is the whole story of the breakage log at the bottom.

```
key → alacritty (emits bytes) → tmux (re-encodes / rewrites) → fish or pi (interprets)
```

## Layer 1 — alacritty

Source: `private_dot_config/alacritty/private_alacritty.toml`.
Host-only: `.chezmoiignore` drops `.config/alacritty` inside containers
(`stat "/.dockerenv"` branch), so the deployed file does not exist in devcontainers.

| Setting | Value | Why |
| --- | --- | --- |
| Shift+Enter | `chars = "\u001b[13;2u"` | Alacritty 0.15.1 does not emit kitty-protocol sequences for modified Enter; pi needs CSI-u to tell it from plain Enter (`tui.input.newLine`) |
| Alt+Enter | `chars = "\u001b[13;3u"` | pi follow-up message queueing |
| Ctrl+Enter | `chars = "\u001b[13;5u"` | future-proofing, nothing consumes it today |
| Ctrl+Shift+C / V | Copy / Paste | terminal-level, never reaches the shell |
| Ctrl+0 / Ctrl+Minus / Numpad ± | font size | — |
| `[env] TERM` | `xterm-256color` | `alacritty` terminfo is missing on too many remote hosts |
| `[terminal] osc52` | `copypaste` | clipboard from inside tmux / over ssh |
| `[general] live_config_reload` | `true` | edits apply without restart |

Not configurable here and worth remembering:

- Ctrl+Backspace emits raw `\x08` (^H). There is no binding for it; everything
  downstream deals with that byte.
- Alacritty answers pi's kitty-keyboard query (`\x1B[<u`) with `\x1B[<1u` — but
  only if tmux lets the query through (see `allow-passthrough` below).
- Alacritty applies the **last** matching `keyboard.bindings` entry. Two entries
  for the same key = the earlier one is dead (this caused the 2026-07-01 regression).

i3 launches it: `$mod+Return` runs `alacritty -q -e sh -c 'exec <tmux config dir>/new-session.sh'`
(see `private_dot_config/i3/config`, source `private_dot_config/tmux/executable_new-session.sh`).
`-q` mutes a harmless XCB clipboard race (alacritty/alacritty#6978).

## Layer 2 — tmux

Deployed: `~/.config/tmux/tmux.conf` — source `private_dot_config/tmux/tmux.conf.tmpl`.

| Setting | Value | Why |
| --- | --- | --- |
| `extended-keys` | `on` | **never `always`** — `always` forces every key through CSI-u, turning Home/End into `\e[72;1u` / `\e[70;1u`, which pi does not map (it expects kitty codepoints 57423/57424). `on` only encodes keys with no traditional representation |
| `extended-keys-format` | `csi-u` | pi warns on the `xterm` default and mis-reads Shift+Enter |
| `allow-passthrough` | `all` | lets pi's kitty query reach alacritty; without it pi never activates its CSI-u parser |
| root binding `C-h` | `send-keys -l \033\177` | rewrites Ctrl+Backspace `\x08` into ESC+DEL so pi and fish see alt+backspace |
| `aggressive-resize` | `on` | resize to the active client, kills scrollback flicker when dragging window edges |
| `escape-time` | `10` | ESC-prefixed sequences are not mistaken for a bare ESC |
| `default-command` | `bash -l` | login bash sources `.profile` → `exec fish`; spawning the mise fish shim directly broke tty ownership (`tcsetattr: I/O error`) |
| `default-terminal` | `tmux-256color` + `RGB`/`Tc` overrides | truecolour under tmux |
| `set-clipboard` | `on` | OSC52 owns the clipboard; a parallel xclip pipe raced alacritty for the X selection |

Prefix is `C-b`; `prefix r` reloads. Splits: `prefix h` stacked, `prefix v`
side-by-side. Pane resize is left at the tmux default (`prefix Ctrl-arrows`).

## Layer 3 — fish

Deployed: `~/.config/fish/conf.d/keybindings.fish`.

Fish never requests kitty mode, so it only sees whatever bytes tmux hands it:

```fish
bind \e\x7f backward-kill-word   # ESC+DEL — what the tmux C-h root binding produces
bind \x08   backward-kill-word   # ^H — raw fallback when there is no tmux
```

Both are needed: the first is the normal path under tmux, the second covers bare
alacritty. Everything else (Home/End, word motions) works off fish defaults —
which is exactly why tmux must not re-encode Home/End.

## Layer 4 — pi

Deployed: `~/.pi/agent/keybindings.json`.

```json
{
  "tui.input.newLine": ["shift+enter", "alt+enter"],
  "tui.editor.deleteWordBackward": ["ctrl+w", "alt+backspace", "ctrl+backspace"],
  "tui.editor.deleteWordForward": ["alt+d", "alt+delete", "ctrl+delete"]
}
```

Behaviour that is not in the file but decides whether it works:

- pi parses CSI-u **only** after the kitty keyboard protocol is negotiated →
  depends on tmux `allow-passthrough all`.
- pi's Bun runtime treats a raw `\x08` as plain backspace on non-Windows, so
  `ctrl+backspace` in the JSON above never fires from the raw byte; the tmux
  root binding to ESC+DEL (= alt+backspace) is what actually triggers it.
- Home/End are matched from standard `\e[H` / `\e[F` / `\eOH` / `\eOF`, not CSI-u.

## The four key journeys

| Key | alacritty | tmux | consumer |
| --- | --- | --- | --- |
| Shift+Enter | `\u001b[13;2u` (explicit binding) | forwarded, `extended-keys on` + `csi-u` | pi → `tui.input.newLine` |
| Ctrl+Backspace | `\x08` (built in) | root `C-h` → `\033\177` (ESC+DEL) | pi → alt+backspace → `deleteWordBackward`; fish → `bind \e\x7f` |
| Home / End | standard `\e[H` / `\e[F` | left alone — requires `extended-keys on`, not `always` | pi and fish defaults |
| Window resize | X11 drag | `aggressive-resize on` | no scrollback jitter |

## Breakage log

| Date | Commit | Symptom | Root cause → fix |
| --- | --- | --- | --- |
| 2026-05-25 | `bd17845` | Shift+Enter inserted no newline in pi | Assumed missing pi binding; added a `ctrl+j` fallback in a new `keybindings.json`. Wrong layer |
| 2026-05-25 | `8eac270` | same | Real cause: alacritty 0.15.1 never sends kitty sequences for modified Enter. Added the `\u001b[13;Nu` char bindings |
| 2026-05-25 | `5009214` | — | Dropped the `ctrl+j` workaround; set `TERM=alacritty` |
| 2026-05-29 | `3800da0` | missing terminfo on other hosts | `TERM` back to `xterm-256color` |
| 2026-07-01 | `dd0c110` | Shift+Enter broke again, only under tmux | A duplicate `key = "Return"` + Shift binding sending ESC+CR shadowed the CSI-u one (alacritty takes the last match) and ESC+CR is mangled by tmux escape-time. Removed the duplicate, added `extended-keys always` |
| 2026-07-01 | `3f88224` | pi warned about extended keys | `extended-keys-format csi-u` |
| 2026-07-01 | `2959b33` | Ctrl+Backspace dead in fish under tmux | `always` + `csi-u` re-encoded it as `\e[127;5u`, which fish has no binding for. Added fish bindings |
| 2026-07-01 | `9b4b5f7` | Ctrl+Backspace dead in pi under tmux | pi's kitty query `\x1B[<u` was blocked by tmux, so its CSI-u parser stayed off. `allow-passthrough all` |
| 2026-07-01 | `1e861a0` | Home/End stopped working in pi | `extended-keys always` encoded them as `\e[72;1u` / `\e[70;1u`; pi only maps kitty codepoints. Switched to `extended-keys on` |
| 2026-07-01 | `138946b` | Ctrl+Backspace dead again after that switch | With `on`, `\x08` has a traditional representation and passes through untouched; pi reads it as plain backspace. Added the `C-h` root binding → ESC+DEL, rebound fish to `\e\x7f`, dropped the `\e[127;5u` binding |
| 2026-07-01 | `354be80` | scrollback flicker when dragging the window edge | tmux recomputed size across all attached clients. `aggressive-resize on` |
| 2026-07-03 / 2026-08-01 | `23f31af`, `5362869` | "Failed to set new owner of XCB selection" | xclip yank raced alacritty for the X selection. OSC52 only (`set-clipboard on`), `alacritty -q` in the i3 binding |

## Invariants — break these and the chain breaks

1. `extended-keys` stays `on`. `always` kills Home/End (`1e861a0`).
2. `allow-passthrough all` stays. Without it pi never turns on CSI-u parsing (`9b4b5f7`).
3. Exactly one alacritty binding per key. The last entry wins silently (`dd0c110`).
4. Ctrl+Backspace is fixed **in tmux** (`\x08` → ESC+DEL), not in pi's JSON. The
   pi entry alone does nothing (`138946b`).
5. Any new modified-key binding must be tested in all four consumers: fish
   prompt, pi TUI, with tmux and without.

## Diagnosing the next regression

```sh
# 1. what bytes does the key actually produce? run inside and outside tmux
cat -v            # then press the key, Ctrl+C to stop

# 2. what is tmux configured to do with it?
tmux show -g extended-keys
tmux show -g extended-keys-format
tmux show -g allow-passthrough
tmux list-keys -T root | grep -i 'C-h'

# 3. what does fish think it is bound to?
bind | grep -i kill-word

# 4. what does pi think?
cat ~/.pi/agent/keybindings.json
```

Compare the bytes seen inside tmux with those outside: if they differ, tmux is
re-encoding and the fix belongs in `~/.config/tmux/tmux.conf`. If they are
identical and only pi misbehaves, it is a kitty-protocol negotiation problem
(`allow-passthrough`), not a binding problem.
