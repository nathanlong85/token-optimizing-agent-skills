# code-review-fetch

Fetch GitHub PR review comments in a compact, token-efficient format for use in AI coding sessions.

**Problem**: fetching reviews via the GitHub API returns 10–35KB of JSON noise per PR. Only a tiny fraction is actionable. This tool extracts just the actionable content:

- **CodeRabbit reviews** (`svc-coderabbit[bot]`): extracts the "Prompt for all review comments with AI agents" block directly from the review body — no inline-comment fetch required.
- **Human reviews**: fetches inline comments once, groups by review round, renders as `In \`path\`: Around line N: [comment_text]`.

Deduplicates by review round using a local cache, so repeat invocations only surface new feedback.

## Requirements

- Python 3.9+ (stdlib only — no `pip install`)
- [`gh` CLI](https://cli.github.com/) authenticated for your GitHub host

## Install

This repo is an [Agent Skill](https://agentskills.io). Symlink or copy the repo root into your tool's skills directory.

### Claude Code

```bash
ln -s /path/to/code-review-fetch ~/.claude/skills/code-review-fetch
```

### Cursor and Gemini CLI

```bash
ln -s /path/to/code-review-fetch ~/.agents/skills/code-review-fetch
```

### Project scope (current repo only)

```bash
# Claude Code
ln -s /path/to/code-review-fetch .claude/skills/code-review-fetch

# Cursor / Gemini CLI
ln -s /path/to/code-review-fetch .agents/skills/code-review-fetch
```

## Usage

After installing, invoke the skill from your AI tool:

```bash
/code-review-fetch <pr_number> [--repo owner/repo] [--host github.example.com] [--clear] [--compact]
```

| Flag | Description |
| --- | --- |
| `<pr_number>` | Pull request number (required) |
| `--repo` | `owner/repo` — inferred from git remote when omitted |
| `--host` | GitHub hostname — inferred from git remote when omitted |
| `--clear` | Delete cached review IDs for this PR, re-fetching all reviews |
| `--compact` | Print reviewer/files summary only (no full comment bodies) |

## Supported GitHub hosts

- `github.com`
- GitHub Enterprise instances (e.g. `github.yourcompany.com`) via `GH_HOST`

The host is inferred automatically from your git remote. Pass `--host` to override.

## Troubleshooting

**`'gh' not found`** — install the [GitHub CLI](https://cli.github.com/).

**`gh repo view` fails** — authenticate: `gh auth login --hostname <host>`. Verify with `gh auth status --hostname <host>`.

**`[No new reviews since last run.]` but you expect reviews** — run with `--clear` to reset the cache for this PR.

## Replying to a specific thread

To reply to a CodeRabbit inline comment thread (only when you disagree or won't fix), fetch comment IDs on demand:

```bash
GH_HOST=<host> gh api repos/<owner>/<repo>/pulls/<pr>/comments \
  --jq '.[] | {id, path, line, body: .body[:100]}'
```

## Cache location

`~/.cache/code-review-fetch/<host>_<owner>_<repo>_<pr>.json`

`--clear` deletes only the target PR's cache file.

## Tests

```bash
python3 -m unittest discover tests
```

No third-party dependencies. Uses stdlib `unittest`.
