#!/usr/bin/env bash
# tmux status-left: $1 is the viewed pane's @ssh_remote_host (fish's `ssh` wrapper sets it), else the local hostname.
# Per-pane, not server-wide: one SSH would otherwise tag every pane, and the tag would stick if that pane were killed.
# The host name is hashed into a small palette of muted tones, so a host always gets the same colour.

host=$1

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