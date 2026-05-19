## Why

Catch-all command registry topics (`other.md`) are useful escape hatches, but they can quietly accumulate related commands that should become first-class topics. Agents need a lightweight, reviewable workflow to periodically propose better organization without putting fuzzy AI classification logic into the deterministic `creg` CLI.

## What Changes

- Add an AI-assisted reclassification workflow to the `command-registry` skill instructions.
- Define when agents should inspect catch-all topics such as `other.md`.
- Require a dry-run migration plan before moving entries.
- Keep `creg` as the deterministic executor for approved moves (`creg move`, `creg validate`).
- Include safeguards for confidence thresholds, singleton entries, rollback commands, and project-vs-global reclassification.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `command-registry-protocol`: Add requirements for AI-assisted catch-all reclassification planning and approval-gated execution.

## Impact

- Affects `skills/command-registry/SKILL.md` by adding workflow instructions.
- May affect `skills/command-registry/evals/evals.json` with a reclassification workflow eval.
- Does not add AI behavior to `scripts/creg`; CLI remains deterministic.
- Does not change registry file format.
