---
name: code-review-fetch
description: Fetch GitHub PR review comments in a compact, token-efficient format. Run this skill when asked to fetch, check, or review PR comments. Extracts CodeRabbit's AI prompt block and synthesizes human inline comments into a uniform format, deduplicating by review round using a local cache.
compatibility: Requires Python 3.9+ (stdlib only) and the gh CLI authenticated for the target GitHub host. Run `gh auth status` to verify.
---

Fetch and display new PR review comments for the given pull request number.

## Usage

```
python3 scripts/fetch.py <pr_number> [--repo owner/repo] [--host github.example.com] [--clear]
```

- `<pr_number>` — required
- `--repo` — inferred from git remote if omitted
- `--host` — inferred from git remote if omitted; use for GitHub Enterprise (e.g. `github.yourcompany.com`)
- `--clear` — delete the cached review IDs for this PR and re-fetch all reviews

## Output

One `=== ... ===` section per new review since the last run. CodeRabbit reviews include the full AI prompt block. Human reviews list each inline comment as `In \`path\`: Around line N: <body>`.

After reading the output, address any actionable findings. Re-run to check for new review rounds — already-seen reviews are suppressed automatically.

## Replying to a specific thread

To reply to a CodeRabbit inline comment (only when you disagree or won't fix), fetch comment IDs on demand:

```bash
GH_HOST=<host> gh api repos/<owner>/<repo>/pulls/<pr>/comments \
  --jq '.[] | {id, path, line, body: .body[:100]}'
```
