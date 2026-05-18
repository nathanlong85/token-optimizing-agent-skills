## 1. Repo scaffolding

- [x] 1.1 Create top-level layout: `SKILL.md`, `scripts/fetch.py`, `README.md`, `tests/`
- [x] 1.2 Add `.gitignore` entries for `__pycache__/`, `.pytest_cache/`, and AI agent config dirs
- [x] 1.3 Pin Python ≥ 3.9 in README usage docs (no `requirements.txt`; stdlib only)

## 2. `scripts/fetch.py` core

- [x] 2.1 Add `argparse` CLI: positional `pr` (int), optional `--repo`, `--host`, `--clear`
- [x] 2.2 Implement `resolve_context()` that short-circuits when both `--repo` and `--host` are provided; otherwise runs `gh repo view --json owner,name,url` to fill missing values; fails fast with stderr message + non-zero exit when `gh` missing or unauthed
- [x] 2.3 Implement `gh_api(path, host)` helper wrapping `subprocess.run(["gh", "api", path, "--paginate"], env={"GH_HOST": host, ...})` and returning parsed JSON
- [x] 2.4 Fetch reviews; filter out `APPROVED`, `DISMISSED`, `PENDING`

## 3. CodeRabbit extraction

- [x] 3.1 Implement `extract_coderabbit_content(body)` matching the `<details>… Prompt for all review comments with AI agents …</details>` block and returning the fenced contents
- [x] 3.2 Implement fallback to `Nitpick comments` / `Comments outside of the diff area` sections
- [x] 3.3 Implement raw-body terminal fallback; emit stderr warning naming review ID and fallback level
- [x] 3.4 Skip the inline-comment fetch entirely when every remaining review is CodeRabbit

## 4. Human review synthesis

- [x] 4.1 Fetch `pulls/<pr>/comments` once when at least one non-CodeRabbit review remains
- [x] 4.2 Group comments by `pull_request_review_id`; pick `line` first, `original_line` as fallback
- [x] 4.3 Render each group as `In \`<path>\`: Around line <n>: <body>` lines
- [x] 4.4 Drop human reviews whose grouped comment list is empty

## 5. Cache layer

- [x] 5.1 Compute cache path `~/.cache/code-review-fetch/<host>_<owner>_<repo>_<pr>.json`; ensure parent dir exists
- [x] 5.2 Load existing `seen_review_ids` set; treat missing/corrupt file as empty
- [x] 5.3 After successful emission, write back updated set with current UTC `last_run` timestamp
- [x] 5.4 Implement `--clear` to delete only the current PR's cache file before fetching

## 6. Output format

- [x] 6.1 Emit `=== CodeRabbit Review #<id> (<YYYY-MM-DD>) ===` / `=== Review by <login> #<id> (<YYYY-MM-DD>) ===` headers with trailing blank line
- [x] 6.2 Print `[<N> new review(s). Cache updated.]` summary at end, or `[No new reviews since last run.]` when nothing emitted
- [x] 6.3 Ensure all human-facing output goes to stdout; warnings and errors go to stderr

## 7. Agent Skills packaging

- [x] 7.1 Create spec-compliant `SKILL.md` at repo root with `name`, `description`, `compatibility` frontmatter and usage instructions referencing `scripts/fetch.py` by relative path
- [x] 7.2 Document install paths in README: `~/.claude/skills/` (Claude Code), `~/.agents/skills/` (Cursor + Gemini CLI), and project-scope equivalents

## 8. Tests

- [x] 8.1 `tests/test_extract.py`: prompt-block extraction, nitpick fallback, raw-body fallback (using fixture bodies)
- [x] 8.2 `tests/test_group_comments.py`: inline-comment grouping by `pull_request_review_id`; empty-group filtering; line vs original_line resolution
- [x] 8.3 `tests/test_cache.py`: load missing file → empty set; round-trip write/read; `--clear` deletes only target PR file
- [x] 8.4 `tests/test_output.py`: header rendering, mixed CodeRabbit + human ordering, summary lines
- [x] 8.5 `tests/test_resolve_context.py`: short-circuit when both `--repo` and `--host` provided; no `gh` call in that path
- [x] 8.6 Wire `python3 -m unittest discover tests` (stdlib `unittest`, no pytest dep) and document in README

## 9. Docs

- [x] 9.1 `README.md`: problem framing, symlink install (global + project, per tool), usage flags, `--clear`, troubleshooting `gh` auth, supported hosts
- [x] 9.2 Note `tests` invocation and zero third-party deps

## 10. Manual verification

- [x] 10.1 Symlink repo into `~/.agents/skills/` and confirm skill is available in Cursor or Gemini CLI
- [x] 10.2 Run `scripts/fetch.py <real-pr> --host github.example.com` against a known CodeRabbit-reviewed PR; confirm prompt block extraction and cache write
- [x] 10.3 Re-run the same command; confirm `[No new reviews since last run.]`
- [x] 10.4 Run against a human-only review PR; confirm grouped inline comments output and that "LGTM" reviews are suppressed
- [x] 10.5 Run with `--clear`; confirm cache file is deleted and reviews re-emerge
