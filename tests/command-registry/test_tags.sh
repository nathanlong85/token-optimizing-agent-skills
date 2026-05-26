#!/usr/bin/env bash
# Tests for tag search, inventory, validation, and upgrade-tags
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREG="$SCRIPT_DIR/../../skills/command-registry/scripts/creg"
PASS=0; FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1 — $2"; FAIL=$((FAIL+1)); }

TMP=$(mktemp -d)
cd "$TMP"
"$CREG" init

REG=".agents/rules/local/command-registry"

# Legacy inline tags
cat >> "$REG/search.md" <<'EOF'

## openspec_status

intent: Show OpenSpec status
tags: openspec status change
verified: openspec status --change "{{change_name}}"

## openspec_list

intent: List OpenSpec changes
tags:
  - openspec
  - list
template: openspec list --json

## deploy_prod

intent: Deploy to production
tags:
  - deploy
  - production
  - deprecated
template: ./deploy.sh production

## deploy_staging

intent: Deploy to staging
tags:
  - deploy
  - staging
template: ./deploy.sh staging
EOF

# Ensure search.md is routable so validate checks entry content, not table drift.
if ! grep -q "| search | search.md |" "$REG/index.md"; then
  tmp_index=$(mktemp)
  awk -v row="| search | search.md |" '/^\|---/ && !done { print; print row; done=1; next } { print }' "$REG/index.md" > "$tmp_index"
  mv "$tmp_index" "$REG/index.md"
fi

# ---- AND tag search --------------------------------------------------------

out=$("$CREG" search --tags openspec,status)
echo "$out" | grep -q "openspec_status" && pass "search --tags requires all tags" || fail "search --tags requires all tags" "openspec_status not found"
echo "$out" | grep -qv "openspec_list" && pass "search --tags excludes partial tag matches" || fail "search --tags excludes partial tag matches" "openspec_list matched"

# ---- ANY tag search --------------------------------------------------------

out2=$("$CREG" search --any-tags list,status)
echo "$out2" | grep -q "openspec_status" && pass "search --any-tags matches first tag" || fail "search --any-tags matches first tag" "openspec_status not found"
echo "$out2" | grep -q "openspec_list" && pass "search --any-tags matches second tag" || fail "search --any-tags matches second tag" "openspec_list not found"

# ---- exclude tag search ----------------------------------------------------

out3=$("$CREG" search --tags deploy --exclude-tags deprecated)
echo "$out3" | grep -q "deploy_staging" && pass "search --exclude-tags keeps allowed entry" || fail "search --exclude-tags keeps allowed entry" "deploy_staging not found"
echo "$out3" | grep -qv "deploy_prod" && pass "search --exclude-tags removes excluded entry" || fail "search --exclude-tags removes excluded entry" "deploy_prod matched"

# ---- keyword + tag filter --------------------------------------------------

out4=$("$CREG" search --tags openspec "status")
echo "$out4" | grep -q "openspec_status" && pass "search combines tag filter and keyword" || fail "search combines tag filter and keyword" "openspec_status not found"

# ---- tags inventory --------------------------------------------------------

out5=$("$CREG" tags)
echo "$out5" | grep -q "deploy" && pass "tags lists vocabulary" || fail "tags lists vocabulary" "deploy not found"

out6=$("$CREG" tags --counts)
echo "$out6" | grep -q "deploy (2)" && pass "tags --counts shows usage" || fail "tags --counts shows usage" "deploy count not found"

out7=$("$CREG" tags --untagged)
echo "$out7" | grep -q "all entries are tagged" && pass "tags --untagged reports when every entry has tags" || fail "tags --untagged reports when every entry has tags" "unexpected output: $out7"

# ---- legacy warning + upgrade-tags -----------------------------------------

val_out=$("$CREG" validate 2>&1 || true)
echo "$val_out" | grep -q "legacy inline tags" && pass "validate warns on legacy inline tags" || fail "validate warns on legacy inline tags" "warning missing: $val_out"

dry_out=$("$CREG" upgrade-tags --dry-run 2>&1)
echo "$dry_out" | grep -q "would upgrade tags for 'openspec_status'" && pass "upgrade-tags --dry-run reports pending changes" || fail "upgrade-tags --dry-run reports pending changes" "output: $dry_out"
grep -q "^tags: openspec status change$" "$REG/search.md" && pass "upgrade-tags dry-run does not modify files" || fail "upgrade-tags dry-run does not modify files" "inline tags rewritten"

"$CREG" upgrade-tags >/dev/null
grep -q "^tags:$" "$REG/search.md" && grep -q "^- openspec$" "$REG/search.md" && pass "upgrade-tags rewrites inline tags to list form" || fail "upgrade-tags rewrites inline tags to list form" "canonical tags missing"

idempotent_out=$("$CREG" upgrade-tags 2>&1)
echo "$idempotent_out" | grep -q "no legacy inline tags found" && pass "upgrade-tags is idempotent" || fail "upgrade-tags is idempotent" "output: $idempotent_out"


# ---- unsupported tag syntax -----------------------------------------------

cat >> "$REG/search.md" <<'EOF'

## bad_tag_syntax

intent: malformed tags block
tags:
  * broken
verified: echo broken
EOF

bad_val_out=$("$CREG" validate 2>&1 || true)
echo "$bad_val_out" | grep -q "unsupported tags syntax" && pass "validate reports unsupported tags syntax" || fail "validate reports unsupported tags syntax" "output: $bad_val_out"
if "$CREG" validate &>/dev/null; then
  fail "validate exits non-zero on unsupported tags syntax" "exited 0"
else
  pass "validate exits non-zero on unsupported tags syntax"
fi

rm -rf "$TMP"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
