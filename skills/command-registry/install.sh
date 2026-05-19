#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREG_SRC="$SCRIPT_DIR/scripts/creg"
INSTALL_DIR="$HOME/.local/bin"
INSTALL_PATH="$INSTALL_DIR/creg"

if [[ ! -f "$CREG_SRC" ]]; then
  echo "Error: creg script not found at $CREG_SRC" >&2
  exit 1
fi

mkdir -p "$INSTALL_DIR"

if [[ -e "$INSTALL_PATH" || -L "$INSTALL_PATH" ]]; then
  read -r -p "creg already exists at $INSTALL_PATH. Overwrite? [y/N] " answer
  case "$answer" in
    [yY]) rm "$INSTALL_PATH" ;;
    *) echo "Aborted."; exit 0 ;;
  esac
fi

ln -s "$CREG_SRC" "$INSTALL_PATH"
echo "Installed: $INSTALL_PATH → $CREG_SRC"
echo ""
echo "Verify with:"
echo "  creg --version"
echo ""
echo "If 'creg' is not found, ensure $INSTALL_DIR is on your PATH:"
echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
