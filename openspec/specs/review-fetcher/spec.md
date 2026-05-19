# review-fetcher Specification

## Purpose
TBD - created by archiving change code-review-fetch. Update Purpose after archive.
## Requirements
### Requirement: Argument and context resolution
The fetcher SHALL accept a positional PR number and optional `--repo`, `--host`, `--clear`, and `--compact` flags. When `--repo` or `--host` is omitted, the fetcher MUST infer the missing values from `gh repo view --json owner,name,url` invoked in the current working directory.

#### Scenario: PR number only, inside a git checkout
- **WHEN** the user runs `scripts/fetch.py 1234` inside a repo whose `origin` points at `git@github.example.com:acme/widgets.git`
- **THEN** the fetcher resolves host to `github.example.com`, owner/repo to `acme/widgets`, and proceeds with PR `1234`

#### Scenario: Explicit overrides win over inference
- **WHEN** the user runs `scripts/fetch.py 42 --repo other-org/other-repo --host github.com`
- **THEN** the fetcher targets `other-org/other-repo` on `github.com` and ignores the current git remote

#### Scenario: `gh` missing or unauthed
- **WHEN** `gh repo view` exits non-zero (binary missing or not authenticated for the resolved host)
- **THEN** the fetcher exits with a non-zero status and prints a stderr message naming the host and pointing at `gh auth status`

### Requirement: Review fetch and state filtering
The fetcher SHALL retrieve every review on the target PR via `gh api repos/<owner>/<repo>/pulls/<pr>/reviews --paginate` (with `GH_HOST` set when host differs from `github.com`) and MUST drop any review whose `state` is `APPROVED`, `DISMISSED`, or `PENDING` before any further processing.

#### Scenario: Drop approved reviews
- **WHEN** the PR has one `APPROVED` review and one `CHANGES_REQUESTED` review
- **THEN** only the `CHANGES_REQUESTED` review is considered for output

#### Scenario: Drop pending drafts
- **WHEN** a review has `state == "PENDING"` (the reviewer has not yet submitted)
- **THEN** that review is excluded from output

### Requirement: CodeRabbit body extraction with fallback chain
For reviews authored by `svc-coderabbit[bot]`, the fetcher SHALL NOT fetch inline comments and SHALL extract actionable content from the review body using this ordered fallback chain:
1. Content inside the fenced code block under the `<details><summary>… Prompt for all review comments with AI agents …</summary>` element.
2. If absent, the markdown sections titled `Nitpick comments` and/or `Comments outside of the diff area`, concatenated in document order.
3. If neither exists, the full review body verbatim.
When the fetcher falls through to (2) or (3), it MUST emit a one-line warning to stderr identifying the review ID and the level reached.

#### Scenario: Prompt block present
- **WHEN** a CodeRabbit review body contains the `Prompt for all review comments with AI agents` details block with a fenced code block inside
- **THEN** the fetcher emits the fenced block's contents and writes no stderr warning

#### Scenario: Prompt block missing but nitpicks present
- **WHEN** a CodeRabbit review body has no prompt block but contains a `Nitpick comments` section
- **THEN** the fetcher emits the nitpicks section text and writes `warning: review <id> fell back to nitpicks/outside-diff sections` to stderr

#### Scenario: No structured sections at all
- **WHEN** a CodeRabbit review body has neither a prompt block nor any of the named fallback sections
- **THEN** the fetcher emits the raw review body and writes a stderr warning naming the review ID and the "raw body" level

### Requirement: Human review synthesis from inline comments
For reviews not authored by `svc-coderabbit[bot]`, the fetcher SHALL fetch `repos/<owner>/<repo>/pulls/<pr>/comments` exactly once per invocation, index every comment by its `pull_request_review_id`, and emit per-review sections listing each grouped comment as `In \`<path>\`: Around line <line>: <body>`. Human reviews with an empty grouped comment set MUST be omitted from output.

#### Scenario: Multiple human reviewers, one inline-comment fetch
- **WHEN** the PR has three reviews from two human reviewers, each with inline comments
- **THEN** the fetcher issues exactly one call to `/pulls/<pr>/comments` and produces one output section per review whose grouped comment list is non-empty

#### Scenario: "LGTM" review with zero inline comments
- **WHEN** a human review has `state == "COMMENTED"` and no inline comments group to its `id`
- **THEN** that review is omitted from output

#### Scenario: Inline comment line resolution
- **WHEN** an inline comment has both `original_line` and `line` populated
- **THEN** the emitted "Around line <n>" uses `line` (the current line on the latest commit), falling back to `original_line` only when `line` is null

### Requirement: Seen-ID cache and dedupe
The fetcher SHALL persist the set of emitted review IDs per PR in a JSON file at `~/.cache/code-review-fetch/<host>_<owner>_<repo>_<pr>.json` (creating the directory if missing) and SHALL suppress any review whose `id` is already present in that file. New IDs MUST be appended only after successful emission. The `--clear` flag MUST delete the current PR's cache file (and only that file) before fetching.

#### Scenario: First run
- **WHEN** no cache file exists for the target PR and the PR has two reviewable reviews
- **THEN** both reviews are emitted and the cache file is written containing both IDs

#### Scenario: Second run with no new reviews
- **WHEN** the cache file already contains every reviewable review's ID
- **THEN** the fetcher prints `[No new reviews since last run.]` and exits 0 without modifying the cache file's `seen_review_ids` array

#### Scenario: `--clear` resets the current PR only
- **WHEN** the user runs `scripts/fetch.py 1234 --clear` and a cache file exists for PR 5678
- **THEN** the PR 1234 cache file is deleted before fetching, but the PR 5678 cache file is untouched

### Requirement: Output format
The fetcher SHALL write all review content to stdout. Each emitted review MUST be introduced by a header line of the form `=== CodeRabbit Review ===` for CodeRabbit reviews or `=== Review by <login> ===` for human reviews, followed by the extracted content, followed by a blank line. After processing, the fetcher MUST print a single status line to **stderr** (not stdout): `[<N> new review(s). Cache updated.]` or `[No new reviews since last run.]` when nothing was emitted.

#### Scenario: Mixed CodeRabbit and human output
- **WHEN** a run emits one CodeRabbit review and one human review by `alice`
- **THEN** stdout contains, in order: `=== CodeRabbit Review ===`, the extracted prompt block, a blank line, `=== Review by alice ===`, the synthesized inline comments, a blank line; and stderr contains `[2 new review(s). Cache updated.]`

#### Scenario: Nothing new to emit
- **WHEN** every reviewable review is already in the cache
- **THEN** stdout is empty and stderr contains exactly `[No new reviews since last run.]`

#### Scenario: Headers contain no ID or date
- **WHEN** any review is emitted
- **THEN** its header line contains neither the review ID nor the submission date

