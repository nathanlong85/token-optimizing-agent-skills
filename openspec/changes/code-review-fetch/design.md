## Context

PR review consumption inside AI coding sessions is one of the heaviest read-only operations a session performs: a single CodeRabbit-reviewed PR plus a couple of human reviewers produces 20–35KB of JSON across `pulls/{pr}/reviews` and `pulls/{pr}/comments`, most of which is diff hunks, URLs, reaction metadata, and avatar fields the assistant never uses. CodeRabbit already condenses every actionable finding into a single fenced block ("Prompt for all review comments with AI agents") inside the review body, and human reviewer feedback lives entirely in inline comments. A small fetch-and-filter script packaged as an [Agent Skill](https://agentskills.io) keeps behavior consistent across Claude Code, Cursor, and Gemini CLI without per-tool wrappers or an install script.

Repo is greenfield (single `LICENSE` + `CLAUDE.md`); no prior architecture to honor. Both `github.com` and GitHub Enterprise instances must be supported. `gh` is assumed installed and authed for whichever host is targeted.

## Goals / Non-Goals

**Goals:**
- One Python script handles fetch, filter, dedupe, format for both CodeRabbit and human reviewers.
- Per-PR seen-ID cache so repeat invocations only print new review rounds.
- Single `SKILL.md` makes the repo installable for Claude Code, Cursor, and Gemini CLI via symlink — no installer script, no per-tool wrappers.
- Stdout output only; no temp files, no environment mutations beyond cache writes.
- Stdlib-only Python; no `pip install` step.

**Non-Goals:**
- Posting replies to review threads (called out as a separate manual `gh api` step).
- Supporting non-GitHub forges (GitLab, Bitbucket).
- Threading replies, resolving comments, or any write actions against GitHub.
- Auto-detecting the active PR from branch state; PR number is required input.
- Auth handling — delegated entirely to `gh`.

## Decisions

### D1: Python over Bash
Python parses JSON, manages a per-PR cache file, and emits structured text more cleanly than `bash + jq`, and runs unmodified on macOS / Linux dev boxes. Stdlib-only (`json`, `subprocess`, `argparse`, `pathlib`, `re`) avoids any `pip` install.

*Alternatives*: Bash+jq (rejected — regex on the CodeRabbit `<details>` block plus cache JSON edits are awkward); Node (rejected — extra runtime requirement vs. macOS-default Python 3).

### D2: Shell out to `gh api`, not raw HTTP
`gh` already handles auth, host routing, pagination, and enterprise certs. Calling `gh api repos/<owner>/<repo>/pulls/<pr>/reviews --paginate` (with `GH_HOST=<host>` env) is shorter and more correct than re-implementing token discovery.

*Alternatives*: `requests` + manual token (rejected — adds dep, duplicates `gh` config); PyGithub (rejected — non-stdlib).

### D3: Fallback chain for CodeRabbit review bodies
1. Extract content inside the fenced block under "Prompt for all review comments with AI agents".
2. If absent, capture the body sections under "Nitpick comments" and "Comments outside of the diff area".
3. If neither exists, emit the entire review body verbatim.

This handles CodeRabbit's known body shapes without us having to chase template changes — if the prompt block disappears in a future release we still surface something useful.

### D4: One inline-comment fetch per PR
For non-CodeRabbit reviewers, `pulls/{pr}/comments` is fetched once and indexed by `pull_request_review_id`. We never issue per-review inline-comment calls, which keeps the API budget at exactly two calls per invocation regardless of reviewer count.

### D5: Cache shape — per-PR JSON file of seen review IDs
```
~/.cache/code-review-fetch/<host>_<owner>_<repo>_<pr>.json
{
  "seen_review_ids": [123, 456, 789],
  "last_run": "2026-05-14T13:30:00Z"
}
```

A new review round emits only its own `id`s; subsequent calls suppress them. `--clear` deletes the file for the current PR only (not the whole cache dir), so concurrent work on other PRs is untouched.

### D6: Skip filters
- Drop reviews with `state ∈ {APPROVED, DISMISSED, PENDING}`.
- Drop human reviews (`state == COMMENTED` / `CHANGES_REQUESTED`) whose grouped inline-comment set is empty (e.g., "LGTM" notes).
- A review with body content but no inline comments AND author is CodeRabbit still falls through D3 and is emitted.

### D7: Agent Skills packaging — no installer
The repo root is the skill directory. `SKILL.md` follows the [Agent Skills specification](https://agentskills.io/specification). `scripts/fetch.py` is referenced by relative path from `SKILL.md`. Users install by symlinking the repo root:

| Tool | Global path | Project path |
|------|-------------|--------------|
| Claude Code | `~/.claude/skills/code-review-fetch` | `.claude/skills/code-review-fetch` |
| Cursor + Gemini CLI | `~/.agents/skills/code-review-fetch` | `.agents/skills/code-review-fetch` |

Cursor and Gemini CLI share the `.agents/skills/` path, so one symlink covers both. No `install.py`, no per-tool wrappers, no `templates/` directory.

*Alternatives*: Custom installer script (rejected — adds maintenance burden and was redundant once we adopted the Agent Skills standard); per-tool wrapper files in `.mdc` / `.toml` format (rejected — non-standard, required tool-specific knowledge that the Agent Skills spec already encodes).

### D8: Stdout-only output
Every assistant tool reads the skill's stdout directly. Writing to a file would force a second read step and lose the token win. If a future caller needs file output they can shell-redirect.

## Risks / Trade-offs

- **CodeRabbit template drift** → D3 fallback chain plus an explicit "raw body" terminal case keeps the script useful even when the prompt block is missing; we emit a one-line warning to stderr when we fall through.
- **`gh` not installed or unauthed for the target host** → fail fast with a clear stderr message pointing at `gh auth status --hostname <host>`; no silent fallback to anonymous calls.
- **Cache divergence across machines** → cache is intentionally local; a fresh checkout sees all reviews. This matches the "skill reduces token waste, not a source of truth" framing.
- **Pagination on huge PRs** → `gh api --paginate` is used for both endpoints; no manual page handling.
- **Stdlib-only constraint** limits us to regex for the CodeRabbit body parse. The block shape is stable enough that a tolerant regex is acceptable; exotic markdown nesting falls through to D3.

## Migration Plan

Greenfield change — no migration. After merge:
1. Clone the repo.
2. Symlink the repo root into the appropriate skills directory (see D7 table).
3. Cache directory is created lazily on first fetch.

Rollback: remove the symlink. Optionally delete `~/.cache/code-review-fetch/`.

## Open Questions

- Whether to expose `--json` output mode for programmatic consumers — deferred until a concrete need surfaces.
