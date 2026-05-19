## Why

AI agents waste significant tokens on trial-and-error when running shell commands — re-discovering the right syntax for `gh api`, project-specific Docker wrappers, CI poll loops, etc. across sessions and projects. Each failed command is also a context-polluting tool result. A structured per-project (and cross-project) registry of verified commands, parameterized templates, and explicit anti-patterns lets agents pick the right form on the first try and accumulate institutional knowledge that survives sessions.

## What Changes

- Add a new `command-registry` skill at `skills/command-registry/`
- Ship a tool-agnostic command registry data format consumable by any AI agent (Claude, Cursor, Gemini, etc.) — markdown topic files with structured `## snake_case_id` entries (intent, tags, verified, template, variants, anti_patterns)
- Ship a CLI tool (`creg`) that writes to the registry: schema validation, dedup, A–Z insertion, automatic topic-file creation, index routing-table updates
- Ship a canonical activation snippet that users inject into agent rules files (`creg inject CLAUDE.md`, `creg inject .cursor/rules/creg.mdc`) so agents consult the registry before running commands
- Support two registry scopes: project (`.agents/rules/local/command-registry/`) and global (`~/.agents/rules/command-registry/`), with project taking precedence; classification rule shipped in the activation snippet so agents know which to write to
- Make installation self-contained — no dependency on any specific skill manager (`skills.sh` or otherwise)

## Capabilities

### New Capabilities

- `command-registry-protocol`: The agent-facing behavioral protocol — when to consult the registry, how to search efficiently, how to classify new commands as project vs global, and the canonical activation snippet that users inject into rules files
- `registry-data-format`: The on-disk data format — directory layout, `index.md` structure with routing table, topic-file conventions, the entry schema (`intent`/`tags`/`verified`/`template`/`variants`/`anti_patterns`), and the project-vs-global scope split
- `creg-cli`: The CLI tool with subcommands `init`, `inject`, `link`, `add`, `search`, `show`, `list`, `move`, `validate`, `status`; the `-g`/`--global` flag for targeting the global registry; schema enforcement, dedup, and routing-table maintenance

### Modified Capabilities

None — this is an entirely new skill alongside `code-review-fetch`.

## Impact

- New directory `skills/command-registry/` — `SKILL.md`, `README.md`, `scripts/creg` (shell script), `install.sh`, template `index.md`
- New tests directory `tests/command-registry/` — covers the `creg` CLI subcommands
- README at repo root — add entry describing the new skill alongside `code-review-fetch`
- No changes to existing skills, no changes to existing tests
- Users adopt the skill manually via their preferred install path (clone, `skills.sh`, or other skill managers) — no constraints on install method
