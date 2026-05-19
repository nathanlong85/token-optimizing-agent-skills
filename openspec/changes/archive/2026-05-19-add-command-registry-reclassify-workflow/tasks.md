# Tasks

## 1. Skill Workflow

- [x] 1.1 Add a catch-all reclassification workflow section to `skills/command-registry/SKILL.md`.
- [x] 1.2 Define dry-run plan fields: proposed topics, entry IDs, rationale, confidence, leave-in-place entries, validation steps, and rollback notes.
- [x] 1.3 Document conservative defaults: three-entry cluster threshold, low-confidence leave-in-place behavior, and singleton move restrictions.
- [x] 1.4 Document project/global scope review and explicit approval for cross-scope moves.

## 2. Evaluation Coverage

- [x] 2.1 Add an eval case for proposing a reclassification plan from `other.md` without making changes.
- [x] 2.2 Add an eval assertion that unapproved plans do not execute `creg move`.
- [x] 2.3 Add an eval assertion that approved plans use `creg move` and run `creg validate`.

## 3. Verification

- [x] 3.1 Run `agentskills validate ./skills/command-registry`.
- [x] 3.2 Run `make test-command-registry`.
- [x] 3.3 Run OpenSpec validation for `add-command-registry-reclassify-workflow`.
