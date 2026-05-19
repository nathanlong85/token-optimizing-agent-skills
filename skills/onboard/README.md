# onboard

Canonical onboarding skill for getting project/task context before implementation.

## What it does

- Parses source inputs (Jira/Asana/GitHub/file/URL/pasted text)
- Supports multi-source onboarding with typed prefixes and source cap
- Preserves inline instructions
- Produces structured onboarding summary + questions/concerns
- Enforces explicit wait-for-go before implementation

## Invocation

- `/onboard PROJ-123`
- `/onboard jira:PROJ-123 asana:1213994804762894`
- `/onboard file:docs/handover.md`

## Related skills

- `onboard-jira` is thin Jira wrapper for ergonomic single-source Jira onboarding.
