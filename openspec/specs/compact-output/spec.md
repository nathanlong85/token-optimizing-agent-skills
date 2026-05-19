# Compact Output Specification

## Purpose

TBD — created as part of the `fetch-token-optimizations` change.

## Requirements

### Requirement: Compact summary mode
When invoked with `--compact`, the fetcher SHALL emit a brief summary of new reviews to stdout instead of full comment bodies, then exit. The summary MUST include the count and logins of new reviewers, followed by a list of files that have inline comments and their comment counts. The status line (`[N new review(s). Cache updated.]`) MUST still be written to stderr. The cache MUST NOT be updated when `--compact` is used — compact mode is read-only.

#### Scenario: New reviews with inline comments
- **WHEN** the user runs `scripts/fetch.py 123 --compact` and there are 2 new reviews from `alice` and `svc-coderabbit[bot]` with inline comments on 3 files
- **THEN** stdout contains a summary of the form `2 new review(s) — alice, svc-coderabbit[bot]` followed by a `Files with comments:` section listing each file and its comment count, and stderr contains `[2 new review(s). Cache updated.]`

#### Scenario: No new reviews in compact mode
- **WHEN** the user runs `scripts/fetch.py 123 --compact` and all reviews are already cached
- **THEN** stdout is empty and stderr contains `[No new reviews since last run.]`

#### Scenario: Compact mode does not update the cache
- **WHEN** the user runs `scripts/fetch.py 123 --compact` and there are new reviews
- **THEN** the cache file is not modified, so a subsequent run without `--compact` still emits the same reviews
