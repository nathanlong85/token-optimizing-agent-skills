## Context

The command registry currently has deterministic storage and maintenance commands (`creg add`, `move`, `validate`, etc.) plus agent instructions for when to consult and update entries. Catch-all topics such as `other.md` are useful for low-friction capture, but they can become stale when multiple related entries accumulate.

This change adds an agent-driven workflow for reclassifying catch-all entries while keeping the shell CLI predictable and non-AI.

## Goals / Non-Goals

**Goals:**

- Give agents a repeatable way to propose topic reclassification for catch-all registry entries.
- Keep all moves approval-gated and executable through `creg move`.
- Encourage clustering only when there is enough signal.
- Include project-vs-global reclassification in the same review when relevant.
- Preserve token efficiency by inspecting targeted entries rather than loading entire registries unnecessarily.

**Non-Goals:**

- Do not put AI classification logic inside `scripts/creg`.
- Do not automatically move entries immediately after `creg add`.
- Do not delete `other.md` or require it to be empty.
- Do not change the registry entry schema.

## Decisions

### Keep reclassification in the skill layer

The agent skill will describe how to inspect catch-all topics and produce a proposed migration plan. `creg` remains a deterministic CLI that validates and executes approved moves.

Alternatives considered:
- Add `creg reclassify`. Rejected because useful classification depends on semantic judgment and should not be hidden inside a shell script.
- Auto-reclassify after each `creg add`. Rejected because it creates surprise churn and makes command capture more expensive.

### Use dry-run plans before execution

The workflow should first present a plan with proposed new topic files, entry IDs, rationale, confidence, and rollback commands. The agent may execute moves only after user approval.

This keeps taxonomy changes reviewable and makes incorrect clusters easy to catch before mutation.

### Default to conservative clustering

The workflow should propose a new topic only when multiple entries form a clear group. Default threshold is three related entries; two-entry clusters can be proposed only when the user asks for aggressive cleanup or the category is obvious.

Singletons stay in `other.md` unless the user names a destination.

### Revisit project/global scope during review

Because classification is also about scope, the workflow should identify entries that appear to belong in the global registry or project registry. Cross-scope moves require explicit mention in the plan and approval before execution.

## Risks / Trade-offs

- [Risk] AI over-groups unrelated commands → Mitigation: require dry-run plan, confidence, rationale, and approval.
- [Risk] Reclassification churn creates harder-to-search registries → Mitigation: conservative thresholds and leave ambiguous entries in `other.md`.
- [Risk] Moving across project/global registries is not a single `creg move` today → Mitigation: plan cross-scope changes separately and require explicit steps or manual copy/add until CLI support exists.
- [Risk] Planning loads too much context → Mitigation: start with `creg list` / targeted `creg show` and only inspect candidate sections.
