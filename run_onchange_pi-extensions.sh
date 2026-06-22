#!/usr/bin/env bash
# Install pi-anthropic-auth extension from the mise-managed npm package.
# The `latest` symlink is updated by `mise up npm:@gotgenes/pi-anthropic-auth`,
# so pi always loads the current version after an upgrade.
set -euo pipefail

PI_BIN="${MISE_INSTALLS_DIR:-$HOME/.local/share/mise/installs}/pi/latest/pi"
PLUGIN_PATH="${MISE_INSTALLS_DIR:-$HOME/.local/share/mise/installs}/npm-gotgenes-pi-anthropic-auth/latest/lib/node_modules/@gotgenes/pi-anthropic-auth"

if [[ ! -d "$PLUGIN_PATH" ]]; then
  echo "pi-anthropic-auth not installed via mise yet; skipping pi install"
  echo "  Run: mise install 'npm:@gotgenes/pi-anthropic-auth'"
  exit 0
fi

"$PI_BIN" install "$PLUGIN_PATH"
