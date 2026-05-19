#!/usr/bin/env bash
# Tests for `creg inject`
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREG="$SCRIPT_DIR/../../skills/command-registry/scripts/creg"
PASS=0; FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1 — $2"; FAIL=$((FAIL+1)); }

TMP=$(mktemp -d)
cd "$TMP"

# ---- plain markdown --------------------------------------------------------

touch CLAUDE.md
"$CREG" inject CLAUDE.md

if grep -q "## Command Registry" CLAUDE.md; then
  pass "inject adds snippet to plain markdown"
else
  fail "inject adds snippet to plain markdown" "marker not found"
fi

# Idempotency
"$CREG" inject CLAUDE.md 2>&1 | grep -q "already contains" && pass "inject idempotent: prints notice" || fail "inject idempotent: prints notice" "no notice"
count=$(grep -c "## Command Registry" CLAUDE.md)
[[ "$count" -eq 1 ]] && pass "inject idempotent: no duplicate" || fail "inject idempotent: no duplicate" "count=$count"

# ---- .mdc new file ---------------------------------------------------------

mkdir -p .cursor/rules
"$CREG" inject .cursor/rules/creg.mdc

if grep -q "alwaysApply: true" .cursor/rules/creg.mdc; then
  pass "inject creates .mdc with alwaysApply frontmatter"
else
  fail "inject creates .mdc with alwaysApply frontmatter" "not found"
fi

if grep -q "## Command Registry" .cursor/rules/creg.mdc; then
  pass "inject adds snippet to .mdc file"
else
  fail "inject adds snippet to .mdc file" "marker not found"
fi

# Idempotency on .mdc
"$CREG" inject .cursor/rules/creg.mdc 2>&1 | grep -q "already contains" && pass ".mdc inject idempotent" || fail ".mdc inject idempotent" "no notice"
count2=$(grep -c "## Command Registry" .cursor/rules/creg.mdc)
[[ "$count2" -eq 1 ]] && pass ".mdc inject no duplicate" || fail ".mdc inject no duplicate" "count=$count2"

# ---- multi-file in one invocation ------------------------------------------

touch GEMINI.md
"$CREG" inject CLAUDE.md GEMINI.md .cursor/rules/creg.mdc

# CLAUDE.md and creg.mdc already have it; GEMINI.md is new
if grep -q "## Command Registry" GEMINI.md; then
  pass "inject multi-file: adds to new file"
else
  fail "inject multi-file: adds to new file" "GEMINI.md missing snippet"
fi

# Still exactly 1 occurrence in CLAUDE.md
count3=$(grep -c "## Command Registry" CLAUDE.md)
[[ "$count3" -eq 1 ]] && pass "inject multi-file: existing file not duplicated" || fail "inject multi-file: existing file not duplicated" "count=$count3"

rm -rf "$TMP"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
