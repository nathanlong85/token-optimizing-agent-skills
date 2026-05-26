## 1. Tag Parsing And Formatting

- [x] 1.1 Add shared bash helpers for parsing canonical `tags:` lists and legacy inline tag strings into normalized tag tokens.
- [x] 1.2 Add shared bash helpers for validating tag tokens, detecting duplicate tags, and rendering canonical bulleted tag lists.
- [x] 1.3 Update `creg add` so `--tags` accepts comma-separated and whitespace-separated input but writes canonical list-form tags.

## 2. Search And Inventory Commands

- [x] 2.1 Extend `creg search` argument parsing to support `--tags`, `--any-tags`, and `--exclude-tags` with exact tag matching.
- [x] 2.2 Update search matching so keyword filters and tag filters compose predictably across project, global, and `--all` searches.
- [x] 2.3 Add `creg tags` with default sorted tag listing, `--counts`, `--untagged`, `-g`, and `--all`.

## 3. Validation And Migration

- [x] 3.1 Extend `creg validate` to report malformed tags, duplicate tags within an entry, and unsupported tag syntax.
- [x] 3.2 Keep legacy inline tag syntax valid while emitting a normalization warning that does not fail validation by itself.
- [x] 3.3 Add `creg upgrade-tags` with `--dry-run`, `-g`, and `--all`, rewriting only legacy inline tags and remaining idempotent.

## 4. Agent Guidance And Documentation

- [x] 4.1 Update the canonical activation snippet in `creg` to mention `creg search --tags` for precise tag filtering.
- [x] 4.2 Update `skills/command-registry/SKILL.md` and registry templates to document canonical tag syntax and tag search usage.
- [x] 4.3 Ensure snippet parity tests cover the updated activation snippet.

## 5. Tests And Validation

- [x] 5.1 Add shell tests for `creg add` writing canonical tags and rejecting invalid tag tokens.
- [x] 5.2 Add shell tests for legacy inline tags, canonical list tags, AND tag search, OR tag search, excluded tags, and keyword-plus-tag searches.
- [x] 5.3 Add shell tests for `creg tags` inventory modes and `creg upgrade-tags` dry-run/idempotent migration behavior.
- [x] 5.4 Run the command-registry test suite and `openspec validate enhanced-tag-filtering --strict`.
- [x] 5.5 Validate the skill with `agentskills validate ./skills/command-registry` when `agentskills` is available.
