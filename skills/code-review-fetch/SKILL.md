---
name: code-review-fetch
description: Use this skill when asked to fetch, check, or review GitHub PR comments. It returns only actionable review content in a compact format, extracts CodeRabbit's AI prompt block, and synthesizes human inline comments while deduplicating previously seen review rounds via a local cache.
compatibility: Requires Python 3.9+ (stdlib only) and the gh CLI authenticated for the target GitHub host. Run `gh auth status` to verify.
---

# code-review-fetch

Fetch and display new PR review comments for the given pull request number.

## Usage

```bash
python3 scripts/fetch.py <pr_number> [--repo owner/repo] [--host github.example.com] [--clear] [--compact]
```

- `<pr_number>` — required
- `--repo` — inferred from git remote if omitted
- `--host` — inferred from git remote if omitted; use for GitHub Enterprise (e.g. `github.yourcompany.com`)
- `--clear` — delete the cached review IDs for this PR and re-fetch all reviews
- `--compact` — print a short reviewer/files summary instead of full review bodies

## Output

Default output is one `=== ... ===` section per new review since the last run. CodeRabbit reviews include the full AI prompt block. Human reviews list each inline comment as `In \`path\`: Around line N: [comment_text]`.

With `--compact`, output is a short summary: reviewer logins plus `Files with comments` counts.

After reading the output, address any actionable findings. Re-run to check for new review rounds — already-seen reviews are suppressed automatically.

## Replying to a specific thread

To reply to a CodeRabbit inline comment (only when you disagree or won't fix), fetch comment IDs on demand:

```bash
GH_HOST=<host> gh api repos/<owner>/<repo>/pulls/<pr>/comments \
  --jq '.[] | {id, path, line, body: .body[:100]}'
```
