## GitHub Issue Source Loading

Use for GitHub issue references from typed source or URL.

## Accepted forms

- `gh:owner/repo#123`
- `gh:#123` (only when repo context is unambiguous)
- `gh:https://github.com/owner/repo/issues/123`
- `https://github.com/owner/repo/issues/123`

## Loading behavior

1. Resolve `owner/repo` and issue number.
2. Fetch only essential fields for onboarding:
   - title
   - body
   - labels
   - assignees
   - state
   - selected comments when needed for context
3. Prefer compact field selection (`--json` with explicit fields) over full payloads.

## Read-only guidance

- Do not comment, close, reopen, or edit issues during onboarding.
- If access is private/unavailable, ask for pasted content and continue with available sources.
