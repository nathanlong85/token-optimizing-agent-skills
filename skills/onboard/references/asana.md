## Asana Source Loading

Use for `asana:<value>` and Asana task URLs.

## Accepted Asana forms

- `asana:1213994804762894`
- `asana:https://app.asana.com/0/<project>/<task>`
- `https://app.asana.com/0/<project>/<task>`

## Loading behavior

1. Normalize to a task identifier and, when present, preserve the original URL.
2. Load only task fields needed for onboarding summary and risk analysis.
3. Keep source data concise; avoid dumping full activity history unless user asks.

## Access strategy

Use whichever is available in this environment, in order:

1. Asana MCP/tooling configured for this workspace
2. Browser-based access if available and authenticated
3. User-provided pasted task content

## Failure handling

- If task content cannot be read due to auth/access limits, ask for pasted task description/comments.
- In multi-source mode, proceed with other sources while noting the missing Asana details.
