## 1. API Field Filtering

- [x] 1.1 Add `--jq` selector to the `/reviews` `gh api` call, keeping only `id`, `state`, `submitted_at`, `body`, and `user.login`
- [x] 1.2 Add `--jq` selector to the `/comments` `gh api` call, keeping only `pull_request_review_id`, `path`, `line`, `original_line`, and `body`
- [x] 1.3 Verify `--jq` composes correctly with `--paginate` (jq applies per-page to an array)

## 2. Output Format

- [x] 2.1 Update CodeRabbit header format from `=== CodeRabbit Review #<id> (<date>) ===` to `=== CodeRabbit Review ===`
- [x] 2.2 Update human review header format from `=== Review by <login> #<id> (<date>) ===` to `=== Review by <login> ===`
- [x] 2.3 Move `[N new review(s). Cache updated.]` from stdout to stderr
- [x] 2.4 Move `[No new reviews since last run.]` from stdout to stderr

## 3. Compact Mode

- [x] 3.1 Add `--compact` argument to the argument parser
- [x] 3.2 Implement compact summary output: reviewer count + logins, then files-with-comments list with per-file counts
- [x] 3.3 Ensure compact mode does not update the cache (read-only pass)
- [x] 3.4 Ensure compact mode still writes the status line to stderr

## 4. Tests

- [x] 4.1 Update header format assertions in `test_output.py` to match new format (no ID, no date)
- [x] 4.2 Update stdout/stderr assertions for the trailing summary line across all affected tests
- [x] 4.3 Add tests for `--compact` output format (reviewer list, file list, comment counts)
- [x] 4.4 Add test asserting compact mode does not mutate the cache
- [x] 4.5 Run full test suite and confirm all tests pass
