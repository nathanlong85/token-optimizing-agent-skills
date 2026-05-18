## Why

Fetching PR review comments inside AI assistant sessions burns large amounts of context on noise: full `pulls/{pr}/reviews` and `pulls/{pr}/comments` responses are 10–35KB of JSON per PR, of which only a tiny fraction is actionable feedback. CodeRabbit already publishes a compact "Prompt for all review comments with AI agents" block in each review body, but humans posting inline comments produce the same problem at higher cost. A shared skill that fetches, filters, deduplicates by review round, and emits a uniform output cuts that step's token cost by roughly 10x and keeps behavior consistent across Claude Code, Cursor, and Gemini CLI.

## What Changes

- Add `scripts/fetch.py`, a Python script that:
  - Accepts a PR number plus optional `--repo`, `--host`, and `--clear` flags; infers repo and host from `gh repo view` when unspecified.
  - Calls `gh api` to fetch reviews; for CodeRabbit reviews extracts the prompt-for-AI block (with fallback to nitpick / outside-diff sections, then raw body); for other reviewers fetches inline comments once and groups them by `pull_request_review_id`.
  - Filters out `APPROVED`, `DISMISSED`, `PENDING` reviews and human reviews with zero inline comments.
  - Maintains a per-PR seen-ID cache at `~/.cache/code-review-fetch/<host>_<owner>_<repo>_<pr>.json` so repeat calls only surface new review rounds; `--clear` deletes the current PR's cache file.
  - Emits a uniform `=== <kind> Review #<id> (<date>) ===` text block on stdout.
- Add a spec-compliant `SKILL.md` at the repo root, making the repo itself an [Agent Skill](https://agentskills.io) installable by Claude Code, Cursor, and Gemini CLI via a single symlink.
- Add `README.md` covering install paths per tool and usage flags.
- Add Python tests for parsing and caching logic (no network).

## Capabilities

### New Capabilities
- `review-fetcher`: Script at `scripts/fetch.py` that fetches GitHub PR reviews, extracts actionable feedback, filters by review state and seen-ID cache, and prints a uniform text format.

### Modified Capabilities
<!-- none — greenfield repo -->

## Impact

- **New files**: `SKILL.md`, `scripts/fetch.py`, `README.md`, `tests/` (Python).
- **Runtime dependencies**: Python 3.9+ (stdlib only), `gh` CLI authenticated for the target host (`github.com` and/or `github.example.com`).
- **Filesystem writes**: `~/.cache/code-review-fetch/` (cache only). No install step — users symlink the repo root into their tool's skills directory.
- **No external services** beyond GitHub via `gh`.
