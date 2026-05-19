## URL Source Loading

Use for `url:<url>` and generic web links.

## Routing behavior

When a URL matches known hosts/patterns, route to source-specific logic:

- Jira browse URL -> `references/jira.md`
- Asana task URL -> `references/asana.md`
- GitHub issue URL -> `references/gh-issue.md`

Otherwise treat as a generic webpage source.

## Generic webpage loading

1. Fetch readable page content.
2. Summarize only task-relevant portions.
3. Keep citation links and key decisions visible in the onboarding summary.

## Failure handling

- If URL requires auth and content is unavailable, ask user to paste relevant content.
- Continue with other sources when in multi-source mode.
