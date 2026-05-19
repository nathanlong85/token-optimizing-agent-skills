#!/usr/bin/env bash
# Tests for `creg search`, `creg show`, `creg list`
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREG="$SCRIPT_DIR/../../skills/command-registry/scripts/creg"
PASS=0; FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1 — $2"; FAIL=$((FAIL+1)); }

TMP=$(mktemp -d)
GLOBAL_TMP=$(mktemp -d)
export CREG_GLOBAL_PATH="$GLOBAL_TMP/creg-global"

cd "$TMP"
"$CREG" init
"$CREG" init -g

# Seed project registry
"$CREG" add git_github pr_view --intent "View a PR" --verified "gh pr view {{pr}}" --tags "github pr"
"$CREG" add ci jenkins_poll --intent "Poll Jenkins CI job" --template "curl -s {{jenkins_url}}/job/{{job}}/lastBuild/api/json" --tags "jenkins ci"

# Seed global registry
"$CREG" add shell rg_search -g --intent "Recursive search with ripgrep" --template "rg -n \"{{pattern}}\" {{path}}" --tags "search grep"

# ---- search project --------------------------------------------------------

out=$("$CREG" search "github")
echo "$out" | grep -q "pr_view" && pass "search matches by tag" || fail "search matches by tag" "pr_view not found"

out2=$("$CREG" search "View a PR")
echo "$out2" | grep -q "pr_view" && pass "search matches by intent" || fail "search matches by intent" "pr_view not found"

out3=$("$CREG" search "jenkins")
echo "$out3" | grep -q "jenkins_poll" && pass "search matches by id keyword" || fail "search matches by id keyword" "jenkins_poll not found"

# ---- search global ---------------------------------------------------------

out4=$("$CREG" search "ripgrep" -g)
echo "$out4" | grep -q "rg_search" && pass "search -g finds global entry" || fail "search -g finds global entry" "rg_search not found"

# ---- search --all ----------------------------------------------------------

out5=$("$CREG" search "search" --all)
echo "$out5" | grep -q "rg_search" && pass "search --all finds global entry" || fail "search --all finds global entry" "rg_search not found"

# ---- show single entry -----------------------------------------------------

out6=$("$CREG" show pr_view)
echo "$out6" | grep -q "^## pr_view$" && pass "show prints entry heading" || fail "show prints entry heading" "heading not found"
echo "$out6" | grep -q "^intent: View a PR$" && pass "show prints intent" || fail "show prints intent" "not found"
echo "$out6" | grep -q "^verified: gh pr view" && pass "show prints verified" || fail "show prints verified" "not found"

# show should not include next entry
echo "$out6" | grep -qv "^## jenkins_poll$" && pass "show stops at next heading" || fail "show stops at next heading" "includes next entry"

# ---- show from global with --all -------------------------------------------

out7=$("$CREG" show rg_search --all)
echo "$out7" | grep -q "^## rg_search$" && pass "show --all finds global entry" || fail "show --all finds global entry" "not found"

# ---- list project ----------------------------------------------------------

out8=$("$CREG" list)
echo "$out8" | grep -q "pr_view" && pass "list shows project entries" || fail "list shows project entries" "not found"

# ---- list global -----------------------------------------------------------

out9=$("$CREG" list -g)
echo "$out9" | grep -q "rg_search" && pass "list -g shows global entries" || fail "list -g shows global entries" "not found"

# ---- list --all ------------------------------------------------------------

out10=$("$CREG" list --all)
echo "$out10" | grep -q "pr_view" && pass "list --all shows project" || fail "list --all shows project" "not found"
echo "$out10" | grep -q "rg_search" && pass "list --all shows global" || fail "list --all shows global" "not found"

rm -rf "$TMP" "$GLOBAL_TMP"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
