## Why

Command registry entries already include tags, but they are written as free-form strings and searched with substring matching. As registries grow, agents need precise, token-efficient tag lookup so they can find the right command shape without broad reads or accidental matches.

## What Changes

- Make `tags:` a structured field with a canonical YAML list format for newly written entries.
- Keep legacy inline tag strings readable so existing registries continue to work without immediate migration.
- Add precise tag filtering to `creg search`, including all-tags, any-tag, and excluded-tag matching.
- Add tag inventory commands for listing tags, usage counts, and entries missing tags.
- Extend validation to catch malformed tags, duplicate tags within an entry, and unsupported tag formats.
- Add an optional migration command that rewrites legacy inline tag strings into the canonical list format.
- Update the canonical activation snippet so agents use `creg search --tags` when they need precise tag filtering.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `registry-data-format`: Defines canonical tag list syntax while accepting existing inline strings as a legacy read format.
- `creg-cli`: Adds structured tag search, tag inventory, validation, and migration behavior.
- `command-registry-protocol`: Updates agent lookup guidance to prefer `creg search --tags` for precise tag discovery.

## Impact

- Affected files: `skills/command-registry/scripts/creg`, `skills/command-registry/SKILL.md`, command-registry templates, tests, and OpenSpec specs.
- Existing registry files remain valid, but new or migrated entries will use list-form tags.
- The activation snippet changes slightly; users can re-run `creg inject` or manually update rules to pick up the new guidance.
