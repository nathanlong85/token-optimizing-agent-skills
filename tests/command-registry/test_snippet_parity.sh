#!/usr/bin/env bash
# Tests for activation snippet/doc parity and key protocol phrases.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREG="$SCRIPT_DIR/../../skills/command-registry/scripts/creg"
SKILL="$SCRIPT_DIR/../../skills/command-registry/SKILL.md"
README="$SCRIPT_DIR/../../skills/command-registry/README.md"
PASS=0; FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1 — $2"; FAIL=$((FAIL+1)); }

if python - "$CREG" "$SKILL" <<'PY'
import difflib
import re
import sys
from pathlib import Path

creg_path, skill_path = sys.argv[1], sys.argv[2]
creg = Path(creg_path).read_text()
skill = Path(skill_path).read_text()

snippet_match = re.search(r"ACTIVATION_SNIPPET='(.*?)'\n\nSNIPPET_MARKER", creg, re.S)
skill_match = re.search(
    r"## Activation Snippet\n\n`creg inject <file>` appends the following snippet verbatim\. Agents that read the file will apply the protocol automatically\.\n\n```(?:[a-zA-Z0-9_-]+)?\n(.*?)\n```",
    skill,
    re.S,
)

if not snippet_match or not skill_match:
    print("Unable to extract activation snippet from one or both files.")
    raise SystemExit(1)

snippet = snippet_match.group(1)
skill_snippet = skill_match.group(1)

if snippet != skill_snippet:
    print("Activation snippet mismatch between scripts/creg and SKILL.md:")
    for line in difflib.unified_diff(
        skill_snippet.splitlines(),
        snippet.splitlines(),
        fromfile="SKILL.md",
        tofile="scripts/creg",
        lineterm="",
    ):
        print(line)
    raise SystemExit(1)

required_retry_line = "  d. If retrying after a failure, re-scan `anti_patterns` in the matched entry before changing command shape."
if required_retry_line not in snippet:
    print("Retry anti_patterns line missing from canonical snippet.")
    raise SystemExit(1)

if "After a command succeeds that is not in the registry" not in snippet:
    print("Canonical snippet missing expected 'is not in the registry' phrasing.")
    raise SystemExit(1)

if "After a command succeeds that isn't in the registry" in snippet:
    print("Canonical snippet contains deprecated contraction phrasing.")
    raise SystemExit(1)
PY
then
  pass "activation snippet in SKILL.md matches scripts/creg and includes retry anti_patterns guidance"
else
  fail "activation snippet parity and protocol phrases" "mismatch or required text missing"
fi

if grep -q "requires bash 4.0 or later" "$CREG"; then
  pass "creg enforces bash 4.0+ at runtime"
else
  fail "creg enforces bash 4.0+ at runtime" "runtime version gate text missing"
fi

if grep -q "\`bash\` (4.0 or later)" "$SKILL"; then
  pass "SKILL.md documents bash 4.0+"
else
  fail "SKILL.md documents bash 4.0+" "version text missing"
fi

if grep -q "\`bash\` 4.0+" "$README"; then
  pass "README.md documents bash 4.0+"
else
  fail "README.md documents bash 4.0+" "version text missing"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
