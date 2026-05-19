## 1. Skill scaffold

- [x] 1.1 Create `skills/command-registry/` directory structure: `SKILL.md`, `README.md`, `install.sh`, `scripts/`, `template/`
- [x] 1.2 Create `tests/command-registry/` directory with `__init__.py`
- [x] 1.3 Add entry for `command-registry` to root `README.md` alongside `code-review-fetch`

## 2. SKILL.md

- [x] 2.1 Write frontmatter with `name`, `description`, `compatibility` (no required tools), `metadata.optional_env_vars: CREG_GLOBAL_PATH`
- [x] 2.2 Write Purpose section explaining what the skill provides
- [x] 2.3 Write Prerequisites section: bash + standard POSIX utilities; verify with `creg --version`
- [x] 2.4 Write CLI discovery instructions (PATH first, fall back to `<SKILL.md dir>/scripts/creg`)
- [x] 2.5 Document the canonical activation snippet verbatim (the same text `creg inject` writes)
- [x] 2.6 Document the project-vs-global classification rule with examples
- [x] 2.7 Document the typical first-use flow (`creg init` → `creg inject` → `creg link --cursor`)

## 3. Template index.md

- [x] 3.1 Create `skills/command-registry/template/index.md` with empty Route table, populated Rules section, and Entry format section
- [x] 3.2 Rules section: when to consult, search-first, lookup priority, same-turn updates, dedup, conflict resolution
- [x] 3.3 Entry format section: `## snake_case_id` heading, field list with descriptions, A–Z sort rule

## 4. `creg` CLI — scaffold

- [x] 4.1 Create `skills/command-registry/scripts/creg` as a bash script with shebang `#!/usr/bin/env bash`, `set -euo pipefail`
- [x] 4.2 Implement top-level argument parser: subcommand dispatch, `--help`, `--version`
- [x] 4.3 Implement registry-path resolution: `find_project_registry` (walk up from `$PWD`), `find_global_registry` (`$CREG_GLOBAL_PATH` || `~/.agents/rules/command-registry`)
- [x] 4.4 Implement `-g` / `--global` flag parsing shared across subcommands that need it

## 5. `creg` CLI — write subcommands

- [x] 5.1 Implement `creg init [-g]`: copy `template/index.md` to target registry directory; idempotent
- [x] 5.2 Implement `creg inject <file...>`: detect `.mdc` vs other; idempotent (check for existing snippet); handle multi-file input
- [x] 5.3 Implement `creg link --cursor`: create `.cursor/rules/local/command-registry` symlink; idempotent
- [x] 5.4 Implement `creg add <topic> <id>` with all entry-field flags; auto-creates topic file and updates index routing table when topic is new
- [x] 5.5 Implement A–Z sorted insertion within topic file (awk or shell-based)
- [x] 5.6 Implement global-id dedup check across all topic files in target registry
- [x] 5.7 Implement `creg move <id> <new-topic> [-g]`: relocate entry, update routing table, delete emptied source file

## 6. `creg` CLI — read subcommands

- [x] 6.1 Implement `creg search <keyword> [-g] [--all]`: grep across `id` / `tags:` / `intent:` / `verified:` / `template:` fields
- [x] 6.2 Implement `creg show <id>`: print the matched `## id` section through the line before the next `##` (or EOF)
- [x] 6.3 Implement `creg list [-g] [--all]`: list all entries with topic file and id

## 7. `creg` CLI — diagnostic subcommands

- [x] 7.1 Implement `creg validate [-g] [--all]`: missing required fields, missing both verified+template, dup ids, drift between routing table and topic files
- [x] 7.2 Implement `creg status`: paths and entry counts for both registries; indicate `CREG_GLOBAL_PATH` override when set

## 8. install.sh

- [x] 8.1 Write `install.sh` that symlinks `skills/command-registry/scripts/creg` to `~/.local/bin/creg`
- [x] 8.2 Detect existing `~/.local/bin/creg` and prompt before overwriting
- [x] 8.3 Print success message with `creg --version` verification instruction

## 9. README.md (skill-level)

- [x] 9.1 Write `skills/command-registry/README.md` with: what it does, why, install options (`install.sh` vs manual vs skill manager), first-use flow
- [x] 9.2 Document the project-vs-global classification rule with worked examples
- [x] 9.3 Document `CREG_GLOBAL_PATH` for the synced-folder (Dropbox/iCloud) use case
- [x] 9.4 Document Cursor/Gemini caveats (Cursor needs `creg link --cursor`; verify Gemini per project)

## 10. Tests

- [x] 10.1 Add `tests/command-registry/test_init.sh` covering project + global init, idempotency
- [x] 10.2 Add `tests/command-registry/test_add.sh` covering: new topic creation, A–Z insertion, dedup rejection, multi-flag entries
- [x] 10.3 Add `tests/command-registry/test_inject.sh` covering: plain markdown, `.mdc` frontmatter, idempotency, multi-file
- [x] 10.4 Add `tests/command-registry/test_link.sh` covering: symlink creation and idempotency
- [x] 10.5 Add `tests/command-registry/test_move.sh` covering: same-registry move, source-file deletion when emptied, routing-table updates
- [x] 10.6 Add `tests/command-registry/test_search_show_list.sh` covering: search across registries, section extraction, `--all` flag
- [x] 10.7 Add `tests/command-registry/test_validate.sh` covering: clean registry pass, schema violations, routing-table drift
- [x] 10.8 Add `tests/command-registry/test_status.sh` covering: both registries present, only project, `CREG_GLOBAL_PATH` override
- [x] 10.9 Run full test suite and confirm all tests pass

## 11. End-to-end verification

- [x] 11.1 In a scratch project: `creg init` → `creg inject CLAUDE.md` → `creg add` → `creg search` round-trip works
- [x] 11.2 Repeat with `-g` against a scratch `CREG_GLOBAL_PATH` directory
- [x] 11.3 Verify the activation snippet written by `creg inject` matches the snippet documented in SKILL.md
