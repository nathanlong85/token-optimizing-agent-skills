#!/usr/bin/env bash
# Tests for `creg validate`
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREG="$SCRIPT_DIR/../../skills/command-registry/scripts/creg"
PASS=0; FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1 — $2"; FAIL=$((FAIL+1)); }

TMP=$(mktemp -d)
cd "$TMP"
"$CREG" init

# ---- clean registry validates -----------------------------------------------

"$CREG" add git_github pr_view --intent "View a PR" --verified "gh pr view {{pr}}"
"$CREG" add git_github pr_list --intent "List PRs" --template "gh pr list --state {{state}}"

val_out=$("$CREG" validate 2>&1 || true)
if echo "$val_out" | grep -q "OK"; then
  pass "validate exits with OK on clean registry"
else
  fail "validate exits with OK on clean registry" "output: $val_out"
fi

if "$CREG" validate &>/dev/null; then
  pass "validate exits 0 on clean registry"
else
  fail "validate exits 0 on clean registry" "non-zero exit"
fi

# ---- missing intent ---------------------------------------------------------

REG=".agents/rules/local/command-registry"
cat >> "$REG/git_github.md" <<'EOF'

## no_intent_entry

verified: some command
EOF

out=$("$CREG" validate 2>&1 || true)
if echo "$out" | grep -q "missing.*intent"; then
  pass "validate detects missing intent"
else
  fail "validate detects missing intent" "not reported. output: $out"
fi

if ! "$CREG" validate &>/dev/null; then
  pass "validate exits non-zero on schema error"
else
  fail "validate exits non-zero on schema error" "exited 0"
fi

# ---- missing both verified and template -------------------------------------

cat >> "$REG/git_github.md" <<'EOF'

## intent_only

intent: This entry has no command
EOF

out2=$("$CREG" validate 2>&1 || true)
if echo "$out2" | grep -q "missing both.*verified.*template\|missing both.*template.*verified"; then
  pass "validate detects missing verified and template"
else
  fail "validate detects missing verified and template" "not reported. output: $out2"
fi

# ---- routing-table drift: topic file not in index ---------------------------

cat > "$REG/orphan.md" <<'EOF'
## orphan_entry

intent: An orphaned entry
verified: orphan_cmd
EOF

out3=$("$CREG" validate 2>&1 || true)
if echo "$out3" | grep -q "not listed in routing table"; then
  pass "validate detects topic file not in routing table"
else
  fail "validate detects topic file not in routing table" "not reported. output: $out3"
fi

rm -rf "$TMP"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
