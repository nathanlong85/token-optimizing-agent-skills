## Why

Command registries are currently easy to edit locally but awkward to share, back up, or review as portable bundles. Import/export support would let users move curated command sets between machines and teams while preserving the markdown registry as the source of truth.

## What Changes

- Add `creg export` to serialize registry entries to a portable structured format.
- Add `creg import` to load exported entries into project or global registries.
- Support dry-run import previews that show new entries, identical entries, and conflicts before writing.
- Add conflict modes for safe default merge behavior, explicit overwrite, and conflict renaming.
- Keep normal registry files in markdown; import/export is a transport layer, not a replacement storage format.
- Validate imported data before modifying registry files and preserve sorted topic-file insertion.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `creg-cli`: Adds import/export subcommands, conflict handling, dry-run previews, and export filtering.
- `registry-data-format`: Defines the portable export envelope and entry schema used by import/export.

## Impact

- Affected files: `skills/command-registry/scripts/creg`, `skills/command-registry/SKILL.md`, command-registry tests, and OpenSpec specs.
- No changes to the primary markdown registry layout.
- No new runtime dependency should be required unless the design explicitly chooses an optional format that can be implemented with existing shell utilities.
