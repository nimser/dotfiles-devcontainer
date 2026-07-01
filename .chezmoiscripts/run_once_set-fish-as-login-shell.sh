#!/usr/bin/bash
# Set fish as the login shell so it's used in SSH, new TTYs, etc.
# Removes the need for the "exec fish" hack in .bashrc.
set -euo pipefail

FISH_PATH=$(command -v fish 2>/dev/null || true)

if [[ -z "$FISH_PATH" ]]; then
    echo "fish not found in PATH — skipping chsh" >&2
    exit 0
fi

# Ensure fish is listed in /etc/shells (required for chsh)
if ! grep -qxF "$FISH_PATH" /etc/shells 2>/dev/null; then
    echo "Adding $FISH_PATH to /etc/shells" >&2
    echo "$FISH_PATH" | sudo tee -a /etc/shells > /dev/null
fi

# Change login shell only if it's not already fish
current=$(getent passwd "$USER" | cut -d: -f7)
if [[ "$current" != "$FISH_PATH" ]]; then
    echo "Changing login shell from $current to $FISH_PATH" >&2
    chsh -s "$FISH_PATH"
else
    echo "Login shell is already $FISH_PATH — nothing to do" >&2
fi
