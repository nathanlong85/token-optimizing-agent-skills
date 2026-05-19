#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREG_SRC="$SCRIPT_DIR/scripts/creg"
INSTALL_DIR="$HOME/.local/bin"
INSTALL_PATH="$INSTALL_DIR/creg"
INSTALL_MODE="ask"
AUTO_OVERWRITE="false"

usage() {
  cat <<'EOF'
Usage: install.sh [--yes | --skip-global-bin]

Options:
  -y, --yes             Install creg to ~/.local/bin without prompting.
  --skip-global-bin     Do not install a global creg symlink.
  -h, --help            Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -y|--yes)
      INSTALL_MODE="yes"
      AUTO_OVERWRITE="true"
      shift
      ;;
    --skip-global-bin)
      INSTALL_MODE="skip"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "$CREG_SRC" ]]; then
  echo "Error: creg script not found at $CREG_SRC" >&2
  exit 1
fi

if [[ "$INSTALL_MODE" == "ask" ]]; then
  if [[ -t 0 ]]; then
    read -r -p "Install creg globally at $INSTALL_PATH? [Y/n] " answer
    case "$answer" in
      [nN]|[nN][oO]) INSTALL_MODE="skip" ;;
      *) INSTALL_MODE="yes" ;;
    esac
  else
    # Non-interactive shells should not block on prompts.
    INSTALL_MODE="yes"
  fi
fi

if [[ "$INSTALL_MODE" == "skip" ]]; then
  echo "Skipped global creg install."
  echo "You can still run it directly:"
  echo "  \"$CREG_SRC\" --version"
  exit 0
fi

mkdir -p "$INSTALL_DIR"

if [[ -e "$INSTALL_PATH" || -L "$INSTALL_PATH" ]]; then
  if [[ -L "$INSTALL_PATH" ]] && [[ "$(readlink "$INSTALL_PATH")" == "$CREG_SRC" ]]; then
    echo "Already installed: $INSTALL_PATH → $CREG_SRC"
    exit 0
  fi

  if [[ "$AUTO_OVERWRITE" == "true" ]]; then
    rm "$INSTALL_PATH"
  elif [[ -t 0 ]]; then
    read -r -p "creg already exists at $INSTALL_PATH. Overwrite? [y/N] " answer
    case "$answer" in
      [yY]) rm "$INSTALL_PATH" ;;
      *) echo "Aborted."; exit 0 ;;
    esac
  else
    echo "Error: $INSTALL_PATH exists and install is non-interactive." >&2
    echo "Rerun with --yes to overwrite automatically." >&2
    exit 1
  fi
fi

ln -s "$CREG_SRC" "$INSTALL_PATH"
echo "Installed: $INSTALL_PATH → $CREG_SRC"
echo ""
echo "Verify with:"
echo "  creg --version"
echo ""
echo "If 'creg' is not found, ensure $INSTALL_DIR is on your PATH:"
echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
