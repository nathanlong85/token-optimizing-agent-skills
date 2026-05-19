#!/usr/bin/env bash
# Tests for `creg link --cursor`
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREG="$SCRIPT_DIR/../../skills/command-registry/scripts/creg"
PASS=0; FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1 — $2"; FAIL=$((FAIL+1)); }

TMP=$(mktemp -d)
cd "$TMP"
"$CREG" init

# ---- symlink created -------------------------------------------------------

"$CREG" link --cursor

LINK_PATH=".cursor/rules/local/command-registry"
if [[ -L "$LINK_PATH" ]]; then
  pass "link --cursor creates symlink"
else
  fail "link --cursor creates symlink" "not a symlink"
fi

# Check symlink target points to project registry
TARGET=$(readlink "$LINK_PATH")
if [[ "$TARGET" == *".agents/rules/local/command-registry" ]]; then
  pass "symlink target is project registry"
else
  fail "symlink target is project registry" "got: $TARGET"
fi

# ---- idempotency -----------------------------------------------------------

"$CREG" link --cursor 2>&1 | grep -qi "already exists" && pass "link --cursor idempotent: prints notice" || fail "link --cursor idempotent: prints notice" "no notice"

# Symlink still correct
TARGET2=$(readlink "$LINK_PATH")
[[ "$TARGET" == "$TARGET2" ]] && pass "link --cursor idempotent: symlink unchanged" || fail "link --cursor idempotent: symlink unchanged" "target changed"

rm -rf "$TMP"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
