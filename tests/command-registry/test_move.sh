#!/usr/bin/env bash
# Tests for `creg move`
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREG="$SCRIPT_DIR/../../skills/command-registry/scripts/creg"
PASS=0; FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1 — $2"; FAIL=$((FAIL+1)); }

TMP=$(mktemp -d)
cd "$TMP"
"$CREG" init

# Seed with entries
"$CREG" add other docker_up --intent "Start docker compose" --verified "docker compose up -d"
"$CREG" add other docker_down --intent "Stop docker compose" --verified "docker compose down"
"$CREG" add other git_status --intent "Show git status" --verified "git status"

# ---- move to new topic file ------------------------------------------------

"$CREG" move docker_up docker

if [[ -f ".agents/rules/local/command-registry/docker.md" ]]; then
  pass "move creates destination topic file"
else
  fail "move creates destination topic file" "missing"
fi

if grep -q "^## docker_up$" ".agents/rules/local/command-registry/docker.md"; then
  pass "move: entry exists in destination"
else
  fail "move: entry exists in destination" "not found"
fi

if ! grep -q "^## docker_up$" ".agents/rules/local/command-registry/other.md"; then
  pass "move: entry removed from source"
else
  fail "move: entry removed from source" "still present"
fi

# Routing table has docker.md
if grep -q "docker.md" ".agents/rules/local/command-registry/index.md"; then
  pass "move: routing table updated with destination"
else
  fail "move: routing table updated with destination" "not in index.md"
fi

# ---- move last entry → source file deleted ---------------------------------

"$CREG" move docker_down docker

# other.md now has only git_status — not deleted yet
if [[ -f ".agents/rules/local/command-registry/other.md" ]]; then
  pass "move: source not deleted while entries remain"
else
  fail "move: source not deleted while entries remain" "deleted prematurely"
fi

"$CREG" move git_status git_github

# other.md should now be deleted
if [[ ! -f ".agents/rules/local/command-registry/other.md" ]]; then
  pass "move: empty source file deleted"
else
  fail "move: empty source file deleted" "file still exists"
fi

# Routing table should not contain other.md
if ! grep -q "other.md" ".agents/rules/local/command-registry/index.md"; then
  pass "move: routing table row removed for deleted file"
else
  fail "move: routing table row removed for deleted file" "row still present"
fi

rm -rf "$TMP"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
