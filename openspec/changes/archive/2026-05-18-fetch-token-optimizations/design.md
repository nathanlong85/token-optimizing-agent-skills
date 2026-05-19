## Context

`skills/code-review-fetch/scripts/fetch.py` currently makes two `gh api` calls that return full GitHub API payloads, then discards most fields in Python. It also emits verbose stdout headers (review ID, date) and a trailing summary line that agents can't act on. The output format is defined in `openspec/specs/review-fetcher/spec.md` and tested in `tests/code-review-fetch/`.

## Goals / Non-Goals

**Goals:**
- Reduce tokens consumed by each invocation at two boundaries: API response size and stdout volume
- Add `--compact` mode for a quick glance before deciding to read the full output

**Non-Goals:**
- Changing what the script outputs semantically (same reviews, same comments, same files)
- Restructuring the cache format or cache location
- Changing existing behavior for `--clear`, `--repo`, `--host`

## Decisions

### `--jq` field selectors on `gh api` calls

**Decision**: Add `--jq` to both `gh api` calls to request only the fields consumed downstream.

`/reviews` — keep: `id`, `state`, `user.login`, `submitted_at`, `body`
```
--jq '[.[] | {id, state, submitted_at, body, user: {login: .user.login}}]'
```

`/comments` — keep: `pull_request_review_id`, `path`, `line`, `original_line`, `body`
```
--jq '[.[] | {pull_request_review_id, path, line, original_line, body}]'
```

**Alternatives considered**: Trimming fields in Python after the fact (current approach). Rejected — the data is already transmitted and decoded; trimming at the source is the right place.

**Note**: `--paginate` and `--jq` compose correctly in `gh`. `--jq` is applied per page before the pages are concatenated, so the expression must work on a JSON array.

### Header simplification

**Decision**: Strip review ID and date from stdout headers. New format:
- CodeRabbit: `=== CodeRabbit Review ===`
- Human: `=== Review by <login> ===`

**Rationale**: Agents navigate to files and lines — they don't reference review IDs or dates in their output. Every character in a header is a token.

**Alternatives considered**: Keeping the ID for potential `gh api` reply flows. Rejected — nothing in this skill posts replies, and the ID is available in the cache if needed.

### Summary line to stderr

**Decision**: Move `[N new review(s). Cache updated.]` and `[No new reviews since last run.]` from stdout to stderr.

**Rationale**: These are operational status messages for the human operator, not actionable content for the agent parsing stdout. Stdout should contain only the review content itself.

### `--compact` flag

**Decision**: `--compact` emits a fixed-width summary to stdout and exits without printing full comment bodies:
```
N new review(s) — <login1>, <login2>
Files with comments:
  path/to/file.py  (N)
  path/to/other.py (N)
```

If there are no new reviews, `--compact` emits nothing to stdout (status line goes to stderr as usual).

**Rationale**: Agents reading a large PR benefit from a cheap first pass to decide whether to engage further. Compact mode makes that possible without parsing full output.

## Risks / Trade-offs

- [Risk] Tests assert the current header format and stdout trailing line → Mitigation: update affected test assertions as part of this change
- [Risk] `--jq` with `--paginate` — each page is a JSON array, so the jq expression must handle arrays → Mitigation: tested locally; `gh` applies jq per-page before concatenation
- [Trade-off] Removing date from headers loses timestamp context → Acceptable; the cache file retains full review metadata if needed
