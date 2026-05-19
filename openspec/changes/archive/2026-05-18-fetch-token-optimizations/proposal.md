## Why

The `review-fetcher` script fetches full GitHub API payloads and emits verbose stdout, delivering more data than an agent needs to act. Every invocation costs unnecessary tokens — both on the wire from the API and in the agent's context window when reading results.

## What Changes

- Add `--jq` field selectors to both `gh api` calls (`/reviews` and `/comments`) to request only the fields the script actually uses, dropping unused fields at the source
- Simplify stdout headers: strip review ID and date, which agents don't act on
- Move the trailing summary line (`[N new review(s). Cache updated.]`) from stdout to stderr, so only actionable content reaches the agent
- Add a `--compact` flag that emits a brief summary (reviewer names, file paths, comment counts) instead of full comment bodies

## Capabilities

### New Capabilities
- `compact-output`: A `--compact` mode that emits a one-page summary — reviewer names, affected files, and comment counts — instead of full comment text

### Modified Capabilities
- `review-fetcher`: Output format requirements change — headers simplified, trailing summary moved to stderr; `--compact` flag added as a supported argument

## Impact

- `skills/code-review-fetch/scripts/fetch.py` — all changes land here
- `openspec/specs/review-fetcher/spec.md` — output format and argument requirements update
- `tests/code-review-fetch/` — tests asserting header format and stdout trailing line will need updating
