#!/usr/bin/env bash
# Tests for `creg add`
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREG="$SCRIPT_DIR/../../skills/command-registry/scripts/creg"
PASS=0; FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1 — $2"; FAIL=$((FAIL+1)); }

TMP=$(mktemp -d)
cd "$TMP"
"$CREG" init

# ---- new topic file created ------------------------------------------------

"$CREG" add git_github pr_view \
  --intent "View a pull request" \
  --verified "gh pr view {{pr}}"

if [[ -f ".agents/rules/local/command-registry/git_github.md" ]]; then
  pass "add creates topic file"
else
  fail "add creates topic file" "missing"
fi

if grep -q "^## pr_view$" ".agents/rules/local/command-registry/git_github.md"; then
  pass "add writes entry heading"
else
  fail "add writes entry heading" "not found"
fi

if grep -q "^intent: View a pull request$" ".agents/rules/local/command-registry/git_github.md"; then
  pass "add writes intent field"
else
  fail "add writes intent field" "not found"
fi

if grep -q "^verified: gh pr view {{pr}}$" ".agents/rules/local/command-registry/git_github.md"; then
  pass "add writes verified field"
else
  fail "add writes verified field" "not found"
fi

# Routing table updated
if grep -q "git_github.md" ".agents/rules/local/command-registry/index.md"; then
  pass "add updates routing table"
else
  fail "add updates routing table" "not found in index.md"
fi

# ---- A-Z sorted insertion --------------------------------------------------

"$CREG" add git_github pr_close \
  --intent "Close a PR" \
  --verified "gh pr close {{pr}}"

"$CREG" add git_github pr_merge \
  --intent "Merge a PR" \
  --verified "gh pr merge {{pr}}"

# Order should be: pr_close, pr_merge, pr_view
content=$(<".agents/rules/local/command-registry/git_github.md")
pos_close=$(grep -n "^## pr_close" ".agents/rules/local/command-registry/git_github.md" | cut -d: -f1)
pos_merge=$(grep -n "^## pr_merge" ".agents/rules/local/command-registry/git_github.md" | cut -d: -f1)
pos_view=$(grep -n "^## pr_view" ".agents/rules/local/command-registry/git_github.md" | cut -d: -f1)

if [[ "$pos_close" -lt "$pos_merge" && "$pos_merge" -lt "$pos_view" ]]; then
  pass "entries inserted in A-Z order"
else
  fail "entries inserted in A-Z order" "pos_close=$pos_close pos_merge=$pos_merge pos_view=$pos_view"
fi

# ---- multi-flag entry (variants and anti_patterns) -------------------------

"$CREG" add git_github pr_list \
  --intent "List open PRs" \
  --verified "gh pr list" \
  --tags "github pull-requests" \
  --variant "gh pr list --state all" \
  --anti-pattern "git log --oneline (doesn't show PR metadata)" \
  --anti-pattern "hub pr list (deprecated)"

if grep -q "^tags: github pull-requests$" ".agents/rules/local/command-registry/git_github.md"; then
  pass "add writes tags field"
else
  fail "add writes tags field" "not found"
fi

if grep -q "^variants:$" ".agents/rules/local/command-registry/git_github.md"; then
  pass "add writes variants section"
else
  fail "add writes variants section" "not found"
fi

ap_count=$(grep -c "^- " ".agents/rules/local/command-registry/git_github.md" || true)
if [[ "$ap_count" -ge 2 ]]; then
  pass "add writes multiple anti_pattern bullets"
else
  fail "add writes multiple anti_pattern bullets" "found $ap_count bullets"
fi

# ---- dedup rejection -------------------------------------------------------
# Capture stderr separately (pipefail makes piping from a failing cmd tricky)

out=$("$CREG" add git_github pr_view --intent "Dup" --verified "gh pr view" 2>&1 || true)
if echo "$out" | grep -q "already exists"; then
  pass "add rejects duplicate id"
else
  fail "add rejects duplicate id" "no error for dup. got: $out"
fi

# ---- missing --intent rejected ---------------------------------------------

out2=$("$CREG" add git_github new_thing --verified "foo" 2>&1 || true)
if echo "$out2" | grep -q "required"; then
  pass "add requires --intent"
else
  fail "add requires --intent" "no error. got: $out2"
fi

# ---- missing verified and template rejected --------------------------------

out3=$("$CREG" add git_github new_thing2 --intent "Something" 2>&1 || true)
if echo "$out3" | grep -q "required"; then
  pass "add requires verified or template"
else
  fail "add requires verified or template" "no error. got: $out3"
fi

rm -rf "$TMP"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
