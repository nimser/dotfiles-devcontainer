#!/usr/bin/env bash
# Create a new tmux session with a short incrementing name: main-1, main-2, ...
n=$(tmux list-sessions -F '#S' 2>/dev/null | grep -E '^main-[0-9]+$' | sed 's/main-//' | sort -n | tail -1)
n=${n:-0}
exec tmux new-session -s "main-$((n+1))"
