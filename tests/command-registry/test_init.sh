#!/usr/bin/env bash
# Tests for `creg init`
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREG="$SCRIPT_DIR/../../skills/command-registry/scripts/creg"
PASS=0; FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1 — $2"; FAIL=$((FAIL+1)); }

# ---- project init ----------------------------------------------------------

TMP=$(mktemp -d)
cd "$TMP"

"$CREG" init
if [[ -f ".agents/rules/local/command-registry/index.md" ]]; then
  pass "init creates project registry index.md"
else
  fail "init creates project registry index.md" "file missing"
fi

# Check template sections present
if grep -q "^## Route" ".agents/rules/local/command-registry/index.md"; then
  pass "index.md contains Route section"
else
  fail "index.md contains Route section" "missing"
fi

if grep -q "^## Rules" ".agents/rules/local/command-registry/index.md"; then
  pass "index.md contains Rules section"
else
  fail "index.md contains Rules section" "missing"
fi

if grep -q "^## Entry Format" ".agents/rules/local/command-registry/index.md"; then
  pass "index.md contains Entry Format section"
else
  fail "index.md contains Entry Format section" "missing"
fi

# Idempotency
"$CREG" init 2>&1 | grep -q "Already initialized" && pass "init idempotent: prints already-initialized message" || fail "init idempotent" "expected 'Already initialized'"
index_before=$(cat ".agents/rules/local/command-registry/index.md")
"$CREG" init 2>/dev/null || true
index_after=$(cat ".agents/rules/local/command-registry/index.md")
[[ "$index_before" == "$index_after" ]] && pass "init idempotent: file unchanged" || fail "init idempotent: file unchanged" "file was modified"

# ---- global init -----------------------------------------------------------

GLOBAL_TMP=$(mktemp -d)
export CREG_GLOBAL_PATH="$GLOBAL_TMP/creg-global"

"$CREG" init -g
if [[ -f "$CREG_GLOBAL_PATH/index.md" ]]; then
  pass "init -g creates global registry index.md"
else
  fail "init -g creates global registry index.md" "file missing"
fi

# Global idempotency
"$CREG" init -g 2>&1 | grep -q "Already initialized" && pass "init -g idempotent" || fail "init -g idempotent" "expected message"

# ---- symlink invocation ----------------------------------------------------

SYMLINK_BIN=$(mktemp -d)
SYMLINK_CREG="$SYMLINK_BIN/creg"
ln -s "$CREG" "$SYMLINK_CREG"

GLOBAL_SYMLINK_TMP=$(mktemp -d)
CREG_GLOBAL_PATH="$GLOBAL_SYMLINK_TMP/creg-global" "$SYMLINK_CREG" init -g
if [[ -f "$GLOBAL_SYMLINK_TMP/creg-global/index.md" ]]; then
  pass "init -g works when creg invoked via symlink"
else
  fail "init -g works when creg invoked via symlink" "global index.md missing"
fi

rm -rf "$TMP" "$GLOBAL_TMP" "$SYMLINK_BIN" "$GLOBAL_SYMLINK_TMP"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
