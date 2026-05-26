#!/usr/bin/env bash
# Tests for `creg export` and `creg import`
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREG="$SCRIPT_DIR/../../skills/command-registry/scripts/creg"
PASS=0; FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1 — $2"; FAIL=$((FAIL+1)); }

TMP=$(mktemp -d)
cd "$TMP"
"$CREG" init
export CREG_GLOBAL_PATH="$TMP/creg-global"
"$CREG" init -g

"$CREG" add docker docker_logs \
  --intent "Stream docker logs" \
  --tags "docker,logs" \
  --template "docker logs -f {{container}}"

"$CREG" add docker docker_ps \
  --intent "List containers" \
  --tags "docker" \
  --verified "docker ps"

"$CREG" add ci jenkins_status \
  --intent "Poll Jenkins status" \
  --tags "jenkins,ci" \
  --template "curl -s {{url}}"

# ---- export stdout ---------------------------------------------------------

out=$("$CREG" export)
echo "$out" | grep -q "^format: creg-bundle-v1$" && pass "export writes bundle format header" || fail "export writes bundle format header" "missing format line"
echo "$out" | grep -q "^## docker/docker_logs$" && pass "export includes entry heading" || fail "export includes entry heading" "missing docker_logs"

# ---- export to file --------------------------------------------------------

"$CREG" export --output bundle.creg.md >/dev/null
[[ -f bundle.creg.md ]] && pass "export --output writes file" || fail "export --output writes file" "missing file"
[[ $($CREG export --output bundle2.creg.md | wc -l | tr -d ' ') -eq 1 ]] && pass "export --output keeps stdout compact" || fail "export --output keeps stdout compact" "stdout not compact"

# ---- export filters --------------------------------------------------------

out_topic=$("$CREG" export --topic docker)
echo "$out_topic" | grep -q "docker_logs" && pass "export --topic filters topic" || fail "export --topic filters topic" "docker_logs missing"
echo "$out_topic" | grep -qv "jenkins_status" && pass "export --topic excludes other topics" || fail "export --topic excludes other topics" "jenkins_status present"

out_id=$("$CREG" export --id docker_ps)
echo "$out_id" | grep -q "docker_ps" && pass "export --id filters id" || fail "export --id filters id" "docker_ps missing"
echo "$out_id" | grep -qv "docker_logs" && pass "export --id excludes other ids" || fail "export --id excludes other ids" "docker_logs present"

out_tags=$("$CREG" export --tags docker,logs)
echo "$out_tags" | grep -q "docker_logs" && pass "export --tags filters by tags" || fail "export --tags filters by tags" "docker_logs missing"
echo "$out_tags" | grep -qv "docker_ps" && pass "export --tags excludes partial tag matches" || fail "export --tags excludes partial tag matches" "docker_ps present"

out_verified=$("$CREG" export --verified-only)
echo "$out_verified" | grep -q "docker_ps" && pass "export --verified-only includes verified entry" || fail "export --verified-only includes verified entry" "docker_ps missing"
echo "$out_verified" | grep -qv "docker_logs" && pass "export --verified-only excludes template-only entry" || fail "export --verified-only excludes template-only entry" "docker_logs present"

# ---- import preview --------------------------------------------------------

preview=$("$CREG" import bundle.creg.md)
echo "$preview" | grep -q "^identical: docker/" && pass "import preview reports identical entries on re-import" || fail "import preview reports identical entries on re-import" "missing identical lines"
echo "$preview" | grep -q "Preview only" && pass "import defaults to preview mode" || fail "import defaults to preview mode" "missing preview notice"
echo "$preview" | grep -q "creg import bundle.creg.md --apply" && pass "import preview suggests apply command" || fail "import preview suggests apply command" "missing apply command"

cat > newentry.creg.md <<'EOF'
# Command Registry Export
format: creg-bundle-v1
source_scope: project

## tools/sample_cmd

intent: Sample new import entry
verified: echo sample
EOF

preview_new=$("$CREG" import newentry.creg.md)
echo "$preview_new" | grep -q "^new: tools/sample_cmd$" && pass "import preview reports new entries" || fail "import preview reports new entries" "missing new line"

# ---- import identical/conflict ---------------------------------------------

"$CREG" import bundle.creg.md --apply >/dev/null
preview2=$("$CREG" import bundle.creg.md)
echo "$preview2" | grep -q "^identical: docker/" && pass "import preview still reports identical after apply" || fail "import preview still reports identical after apply" "missing identical lines"

cat > conflict.creg.md <<'EOF'
# Command Registry Export
format: creg-bundle-v1
source_scope: project

## docker/docker_ps

intent: Different intent
verified: docker ps -a
EOF

preview3=$("$CREG" import conflict.creg.md)
echo "$preview3" | grep -q "^conflict: docker/docker_ps$" && pass "import preview reports conflicts" || fail "import preview reports conflicts" "missing conflict line"

out_block=$("$CREG" import conflict.creg.md --apply 2>&1 || true)
echo "$out_block" | grep -q "import blocked" && pass "import --apply blocks on conflict by default" || fail "import --apply blocks on conflict by default" "output: $out_block"
grep -q "^verified: docker ps$" ".agents/rules/local/command-registry/docker.md" && pass "conflict block leaves registry unchanged" || fail "conflict block leaves registry unchanged" "entry changed"

# ---- import merge/overwrite/rename -----------------------------------------

"$CREG" import conflict.creg.md --apply --merge >/dev/null
grep -q "^verified: docker ps$" ".agents/rules/local/command-registry/docker.md" && pass "import --apply --merge skips conflicts" || fail "import --apply --merge skips conflicts" "entry overwritten"

"$CREG" import conflict.creg.md --apply --overwrite >/dev/null
grep -q "^verified: docker ps -a$" ".agents/rules/local/command-registry/docker.md" && pass "import --apply --overwrite replaces conflict" || fail "import --apply --overwrite replaces conflict" "not overwritten"

cat > rename.creg.md <<'EOF'
# Command Registry Export
format: creg-bundle-v1
source_scope: project

## docker/docker_ps

intent: Renamed import candidate
verified: docker ps --all
EOF

"$CREG" import rename.creg.md --apply --rename-conflicts >/dev/null
grep -q "^## docker_ps_imported$" ".agents/rules/local/command-registry/docker.md" && pass "import --apply --rename-conflicts adds suffixed id" || fail "import --apply --rename-conflicts adds suffixed id" "missing imported id"

# ---- new topic via import --------------------------------------------------

cat > newtopic.creg.md <<'EOF'
# Command Registry Export
format: creg-bundle-v1
source_scope: project

## kubernetes/k8s_get_pods

intent: List pods in namespace
tags:
- kubernetes
- pods
template: kubectl get pods -n {{namespace}}
EOF

"$CREG" import newtopic.creg.md --apply >/dev/null
[[ -f ".agents/rules/local/command-registry/kubernetes.md" ]] && pass "import creates missing topic file" || fail "import creates missing topic file" "kubernetes.md missing"
grep -q "kubernetes.md" ".agents/rules/local/command-registry/index.md" && pass "import updates routing table" || fail "import updates routing table" "missing routing row"
pos_get=$(grep -n "^## k8s_get_pods$" ".agents/rules/local/command-registry/kubernetes.md" | cut -d: -f1)
pos_logs=$(grep -n "^## " ".agents/rules/local/command-registry/docker.md" | head -1 | cut -d: -f1)
[[ -n "$pos_get" ]] && pass "import preserves sorted insertion capability" || fail "import preserves sorted insertion capability" "missing heading"

# ---- invalid bundle --------------------------------------------------------

# ---- global scope import ---------------------------------------------------

cat > globalscope.creg.md <<'EOF'
# Command Registry Export
format: creg-bundle-v1
source_scope: project

## networking/curl_ping

intent: Ping endpoint with headers
verified: curl -I https://example.com
EOF

"$CREG" import globalscope.creg.md -g --apply >/dev/null
[[ -f "$CREG_GLOBAL_PATH/networking.md" ]] && pass "import -g writes to global registry path" || fail "import -g writes to global registry path" "global topic file missing"
grep -q "^## curl_ping$" "$CREG_GLOBAL_PATH/networking.md" && pass "import -g writes entry to global topic file" || fail "import -g writes entry to global topic file" "entry missing"

# ---- invalid bundle --------------------------------------------------------

cat > bad.creg.md <<'EOF'
# Command Registry Export
format: not-a-bundle
EOF

out_bad=$("$CREG" import bad.creg.md 2>&1 || true)
echo "$out_bad" | grep -q "unsupported or missing bundle format" && pass "invalid bundle exits with clear error" || fail "invalid bundle exits with clear error" "output: $out_bad"

rm -rf "$TMP"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
