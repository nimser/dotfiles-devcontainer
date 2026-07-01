#!/usr/bin/env bash
# status-left segment for tmux.
#   - If @ssh_remote_host is set (by the fish `ssh` wrapper when it runs inside tmux on the host),
#     show it on a subtle, stable per-host colour, so the bar clearly tells you which devpod/host
#     a pane is SSH'd into.
#   - Otherwise show the local hostname (so the bar always says where tmux itself is running).
#
# Per-host colour: a small palette of muted dark tones; the host name is hashed to pick one index,
# so the same host always gets the same colour, and different hosts differ subtly.

host=$(tmux show-options -gv @ssh_remote_host 2>/dev/null)

if [ -n "$host" ]; then
    # muted Catppuccin Macchiato tints (subtle, never glaring against #24273a)
    palette=(
        "#2d3a4d"  # indigo
        "#2d4042"  # teal
        "#3a3346"  # plum
        "#3a3b2f"  # olive
        "#332f48"  # violet
        "#2f3847"  # slate
        "#382f3f"  # dark mauve
        "#2d3b40"  # sea
    )
    idx=$(printf '%s' "$host" | cksum | awk -v n="${#palette[@]}" '{print $1 % n}')
    bg=${palette[idx]}
    printf '#[bg=%s,fg=#cad3f5,bold]  ssh:%s  #[bg=#24273a]' "$bg" "$host"
else
    printf '#[fg=#9a9a9a]  %s ' "$(hostname)"
fi