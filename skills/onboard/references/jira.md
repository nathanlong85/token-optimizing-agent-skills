## Jira Source Loading

Use for `jira:<value>`, Jira URLs, or single-source shorthand like `PROJ-123`.

## Accepted Jira forms

- `jira:PROJ-123`
- `jira:PROJ-123,PROJ-456`
- `https://<host>.atlassian.net/browse/PROJ-123`
- `PROJ-123` (only when used as single-source shorthand)

## Loading behavior

1. Normalize to one or more Jira issue keys.
2. If a single issue key is provided and inline instructions do not forbid it, also load parent Epic context when available.
3. If inline instructions include `no epic`, `skip parent`, or equivalent, do not load parent.
4. Keep output compact: fetch only fields needed for onboarding summary and concerns.

## Read-only guidance

- Do not transition issues or add comments during onboarding.
- Prefer command shapes from `command-registry` when available and activated.
- `jira-fetch` is intentionally deferred; use existing Jira tools and compact field selection.

## Failure handling

- If Jira access fails, ask for pasted issue content or a local handover file.
- Continue onboarding with other sources if this is a multi-source run.
