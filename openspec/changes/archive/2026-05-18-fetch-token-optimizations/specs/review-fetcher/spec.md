## MODIFIED Requirements

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
