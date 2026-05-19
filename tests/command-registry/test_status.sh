#!/usr/bin/env bash
# Tests for `creg status`
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREG="$SCRIPT_DIR/../../skills/command-registry/scripts/creg"
PASS=0; FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1 — $2"; FAIL=$((FAIL+1)); }

# ---- only project registry -------------------------------------------------

TMP=$(mktemp -d)
GLOBAL_TMP=$(mktemp -d)
export CREG_GLOBAL_PATH="$GLOBAL_TMP/creg-global-status-test"

cd "$TMP"
"$CREG" init

out=$("$CREG" status)
if echo "$out" | grep -q "Project registry:"; then
  pass "status shows project registry"
else
  fail "status shows project registry" "not found. output: $out"
fi

if echo "$out" | grep -q "Global registry: not initialized"; then
  pass "status shows global not initialized"
else
  fail "status shows global not initialized" "not found. output: $out"
fi

# ---- both registries -------------------------------------------------------

"$CREG" init -g
"$CREG" add git_github pr_view --intent "View PR" --verified "gh pr view {{pr}}"
"$CREG" add shell rg_search -g --intent "Search files" --template "rg \"{{pattern}}\""

out2=$("$CREG" status)
if echo "$out2" | grep -q "Entries: 1"; then
  pass "status shows entry count for project"
else
  fail "status shows entry count for project" "not found. output: $out2"
fi

if echo "$out2" | grep -q "Global registry:"; then
  pass "status shows global registry"
else
  fail "status shows global registry" "not found. output: $out2"
fi

# ---- CREG_GLOBAL_PATH override shown ---------------------------------------

if echo "$out2" | grep -q 'via $CREG_GLOBAL_PATH'; then
  pass "status indicates CREG_GLOBAL_PATH override"
else
  fail "status indicates CREG_GLOBAL_PATH override" "not found. output: $out2"
fi

rm -rf "$TMP" "$GLOBAL_TMP"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
