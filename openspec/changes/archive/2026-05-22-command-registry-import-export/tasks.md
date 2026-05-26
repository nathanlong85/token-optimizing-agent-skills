## 1. Bundle Format Helpers

- [x] 1.1 Add helpers to render `creg-bundle-v1` headers and `## <topic>/<id>` entry headings.
- [x] 1.2 Add helpers to parse bundle metadata and entry sections without external parser dependencies.
- [x] 1.3 Add validation for bundle format, safe topic names, safe entry ids, required entry fields, and unsupported headings.
- [x] 1.4 Add normalized entry-body comparison for identifying identical versus conflicting imports.

## 2. Export Command

- [x] 2.1 Add `creg export` argument parsing for `-g`, `--all`, `--topic`, `--id`, `--tags`, `--verified-only`, and `--output`.
- [x] 2.2 Implement project/global registry traversal that emits deterministic `creg-bundle-v1` output.
- [x] 2.3 Implement export filters before rendering so large registries can be exported selectively.
- [x] 2.4 Ensure stdout behavior is bundle-only when `--output` is absent and compact status-only when `--output` is present.

## 3. Import Planning

- [x] 3.1 Add `creg import <file>` argument parsing for target scope and preview/apply modes.
- [x] 3.2 Implement dry-run default behavior that parses the bundle and reports `new`, `identical`, and `conflict` entries without writes.
- [x] 3.3 Ensure invalid bundles exit non-zero and leave registry files unchanged.
- [x] 3.4 Include the suggested `--apply` command in successful preview output.

## 4. Import Apply And Conflicts

- [x] 4.1 Implement default `--apply` behavior that adds new entries, skips identical entries, and blocks all writes when conflicts exist.
- [x] 4.2 Implement `--apply --merge` to add new entries and skip conflicts with explicit reporting.
- [x] 4.3 Implement `--apply --overwrite` to replace conflicting target entries with imported entries.
- [x] 4.4 Implement `--apply --rename-conflicts` using deterministic `_imported` ids and collision detection.
- [x] 4.5 Ensure applied imports create missing topic files, update `index.md`, and preserve A-Z entry sorting.

## 5. Documentation And Help

- [x] 5.1 Update `creg --help` with import/export usage and conflict mode summaries.
- [x] 5.2 Update `skills/command-registry/SKILL.md` with the bundle format, safe default import behavior, and examples.
- [x] 5.3 Document that JSON/YAML import is intentionally out of scope until parser dependencies are introduced.

## 6. Tests And Validation

- [x] 6.1 Add shell tests for export to stdout, export to file, topic/id/tag filtering, and verified-only filtering.
- [x] 6.2 Add shell tests for import preview classifications: `new`, `identical`, `conflict`, and invalid bundle.
- [x] 6.3 Add shell tests for apply default behavior, `--merge`, `--overwrite`, and `--rename-conflicts`.
- [x] 6.4 Add shell tests that verify missing topic creation, routing-table updates, sorted insertion, and no writes on failed validation.
- [x] 6.5 Run the command-registry test suite and `openspec validate command-registry-import-export --strict`.
- [x] 6.6 Validate the skill with `agentskills validate ./skills/command-registry` when `agentskills` is available.
