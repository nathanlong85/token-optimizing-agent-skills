#!/usr/bin/env python3
"""Fetch and filter GitHub PR review comments, emitting only actionable content."""

import argparse
import json
import os
import re
import subprocess
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urlparse

CODERABBIT_LOGIN = "svc-coderabbit[bot]"
SKIP_STATES = {"APPROVED", "DISMISSED", "PENDING"}
CACHE_DIR = Path.home() / ".cache" / "code-review-fetch"

_JQ_REVIEWS = '[.[] | {id, state, submitted_at, body, user: {login: .user.login}}]'
_JQ_COMMENTS = '[.[] | {pull_request_review_id, path, line, original_line, body}]'


# ---------------------------------------------------------------------------
# gh helpers
# ---------------------------------------------------------------------------

def _gh_env(host: str) -> dict:
    env = os.environ.copy()
    if host and host != "github.com":
        env["GH_HOST"] = host
    return env


def resolve_context(repo: str | None, host: str | None) -> tuple[str, str, str]:
    """Return (host, owner, repo_name). Infer missing values via gh."""
    if repo is not None and host is not None:
        owner, repo_name = repo.split("/", 1)
        return host, owner, repo_name

    try:
        result = subprocess.run(
            ["gh", "repo", "view", "--json", "owner,name,url"],
            capture_output=True, text=True, check=True,
        )
    except FileNotFoundError:
        inferred_host = host or "github.com"
        print(
            f"error: 'gh' not found. Install the GitHub CLI and run 'gh auth login --hostname {inferred_host}'.",
            file=sys.stderr,
        )
        sys.exit(1)
    except subprocess.CalledProcessError as exc:
        inferred_host = host or "github.com"
        print(
            f"error: 'gh repo view' failed (exit {exc.returncode}). "
            f"Run 'gh auth status --hostname {inferred_host}' to verify authentication.",
            file=sys.stderr,
        )
        sys.exit(1)

    data = json.loads(result.stdout)
    if repo is None:
        repo = f"{data['owner']['login']}/{data['name']}"
    if host is None:
        url = data.get("url", "")
        if "github.com" in url:
            host = "github.com"
        else:
            host = urlparse(url).hostname or "github.com"

    owner, repo_name = repo.split("/", 1)
    return host, owner, repo_name


def gh_api(path: str, host: str, jq: str | None = None) -> list:
    """Call gh api --paginate and return parsed JSON."""
    cmd = ["gh", "api", path, "--paginate"]
    if jq:
        cmd += ["--jq", jq]
    try:
        result = subprocess.run(
            cmd,
            capture_output=True, text=True, check=True,
            env=_gh_env(host),
        )
    except FileNotFoundError:
        print(
            f"error: 'gh' not found. Install the GitHub CLI and run 'gh auth login --hostname {host}'.",
            file=sys.stderr,
        )
        sys.exit(1)
    except subprocess.CalledProcessError as exc:
        print(
            f"error: gh api {path!r} failed (exit {exc.returncode}). "
            f"Run 'gh auth status --hostname {host}' to verify authentication.\n{exc.stderr.strip()}",
            file=sys.stderr,
        )
        sys.exit(1)

    # gh --paginate may emit multiple JSON arrays on the same stream; merge them
    raw = result.stdout.strip()
    if not raw:
        return []
    # If paginated, gh joins arrays by concatenating JSON; handle both shapes
    try:
        parsed = json.loads(raw)
        if isinstance(parsed, list):
            return parsed
        return [parsed]
    except json.JSONDecodeError:
        # Multiple top-level arrays: collect all items
        items = []
        decoder = json.JSONDecoder()
        idx = 0
        while idx < len(raw):
            while idx < len(raw) and raw[idx] in " \t\n\r":
                idx += 1
            if idx >= len(raw):
                break
            obj, end = decoder.raw_decode(raw, idx)
            if isinstance(obj, list):
                items.extend(obj)
            else:
                items.append(obj)
            idx = end
        return items


# ---------------------------------------------------------------------------
# CodeRabbit extraction
# ---------------------------------------------------------------------------

def _extract_fenced_block(text: str) -> str | None:
    """Extract content from the first fenced code block (``` ... ```)."""
    m = re.search(r"```[^\n]*\n(.*?)```", text, re.DOTALL)
    return m.group(1).strip() if m else None


def _extract_sections(body: str, *headings: str) -> str | None:
    """Extract content under any of the given markdown headings."""
    parts = []
    for heading in headings:
        pattern = rf"#+\s*{re.escape(heading)}\s*\n(.*?)(?=\n#+\s|\Z)"
        m = re.search(pattern, body, re.DOTALL | re.IGNORECASE)
        if m:
            parts.append(m.group(1).strip())
    return "\n\n".join(parts) if parts else None


def extract_coderabbit_content(body: str, review_id: int) -> str:
    """Extract actionable content from a CodeRabbit review body."""
    # Level 1: prompt block inside <details>
    details_m = re.search(
        r"<details[^>]*>.*?Prompt for all review comments with AI agents.*?</summary>(.*?)</details>",
        body, re.DOTALL | re.IGNORECASE,
    )
    if details_m:
        block = _extract_fenced_block(details_m.group(1))
        if block:
            return block

    # Level 2: named sections
    sections = _extract_sections(body, "Nitpick comments", "Comments outside of the diff area")
    if sections:
        print(
            f"warning: review {review_id} fell back to nitpicks/outside-diff sections",
            file=sys.stderr,
        )
        return sections

    # Level 3: raw body
    print(
        f"warning: review {review_id} fell back to raw body (no structured sections found)",
        file=sys.stderr,
    )
    return body.strip()


# ---------------------------------------------------------------------------
# Human review synthesis
# ---------------------------------------------------------------------------

def group_inline_comments(comments: list) -> dict[int, list]:
    """Return {review_id: [comment, ...]} for all inline comments."""
    grouped: dict[int, list] = defaultdict(list)
    for c in comments:
        rid = c.get("pull_request_review_id")
        if rid is not None:
            grouped[rid].append(c)
    return dict(grouped)


def render_human_review(review_id: int, grouped: dict[int, list]) -> str | None:
    """Render inline comments for a review; return None if empty."""
    comments = grouped.get(review_id, [])
    if not comments:
        return None
    lines = []
    for c in comments:
        path = c.get("path", "?")
        line = c.get("line") or c.get("original_line") or "?"
        body = c.get("body", "").strip()
        lines.append(f"In `{path}`: Around line {line}: {body}")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Cache
# ---------------------------------------------------------------------------

def _cache_path(host: str, owner: str, repo_name: str, pr: int) -> Path:
    safe = f"{host}_{owner}_{repo_name}_{pr}".replace("/", "_")
    return CACHE_DIR / f"{safe}.json"


def load_cache(path: Path) -> set[int]:
    if not path.exists():
        return set()
    try:
        data = json.loads(path.read_text())
        return set(data.get("seen_review_ids", []))
    except (json.JSONDecodeError, OSError):
        return set()


def save_cache(path: Path, seen: set[int]) -> None:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps({
        "seen_review_ids": sorted(seen),
        "last_run": datetime.now(timezone.utc).isoformat(),
    }, indent=2))


# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------

def _format_date(submitted_at: str) -> str:
    if not submitted_at:
        return "unknown"
    return submitted_at[:10]


# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

def _emit_compact_summary(new_reviews: list, api_base: str, host: str) -> None:
    """Print compact reviewer + file summary to stdout; status line to stderr."""
    logins = [r.get("user", {}).get("login", "unknown") for r in new_reviews]
    print(f"{len(new_reviews)} new review(s) — {', '.join(logins)}")

    comments = gh_api(f"{api_base}/comments", host, jq=_JQ_COMMENTS)
    new_review_ids = {r["id"] for r in new_reviews}
    file_counts: dict[str, int] = defaultdict(int)
    for c in comments:
        if c.get("pull_request_review_id") in new_review_ids:
            file_counts[c.get("path", "?")] += 1

    if file_counts:
        print("Files with comments:")
        for path, count in sorted(file_counts.items()):
            print(f"  {path} ({count})")

    print(f"[{len(new_reviews)} new review(s). Cache updated.]", file=sys.stderr)


def _emit_full_reviews(new_reviews: list, api_base: str, host: str) -> list[int]:
    """Print full review content to stdout; return IDs of emitted reviews."""
    non_coderabbit = [r for r in new_reviews if r.get("user", {}).get("login") != CODERABBIT_LOGIN]

    grouped: dict[int, list] = {}
    if non_coderabbit:
        inline_comments = gh_api(f"{api_base}/comments", host, jq=_JQ_COMMENTS)
        grouped = group_inline_comments(inline_comments)

    emitted_ids: list[int] = []
    for review in new_reviews:
        rid = review["id"]
        login = review.get("user", {}).get("login", "unknown")
        body = review.get("body") or ""

        if login == CODERABBIT_LOGIN:
            print("=== CodeRabbit Review ===")
            print(extract_coderabbit_content(body, rid))
            print()
            emitted_ids.append(rid)
        else:
            rendered = render_human_review(rid, grouped)
            if rendered is None:
                continue  # no inline comments — skip (e.g. "LGTM")
            print(f"=== Review by {login} ===")
            print(rendered)
            print()
            emitted_ids.append(rid)

    return emitted_ids


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Fetch GitHub PR review comments in a token-friendly format.",
    )
    parser.add_argument("pr", type=int, help="Pull request number")
    parser.add_argument("--repo", help="owner/repo (inferred from git remote if omitted)")
    parser.add_argument("--host", help="GitHub hostname (default: inferred from remote)")
    parser.add_argument("--clear", action="store_true", help="Delete cached review IDs for this PR before fetching")
    parser.add_argument("--compact", action="store_true", help="Emit a brief summary (reviewers, files, counts) instead of full comment bodies")
    args = parser.parse_args()

    host, owner, repo_name = resolve_context(args.repo, args.host)
    api_base = f"repos/{owner}/{repo_name}/pulls/{args.pr}"

    cache_file = _cache_path(host, owner, repo_name, args.pr)
    if args.clear and cache_file.exists():
        cache_file.unlink()
    seen = load_cache(cache_file)

    reviews = gh_api(f"{api_base}/reviews", host, jq=_JQ_REVIEWS)
    new_reviews = [r for r in reviews if r.get("state") not in SKIP_STATES and r["id"] not in seen]

    if not new_reviews:
        print("[No new reviews since last run.]", file=sys.stderr)
        return

    if args.compact:
        _emit_compact_summary(new_reviews, api_base, host)
        return

    emitted_ids = _emit_full_reviews(new_reviews, api_base, host)

    if not emitted_ids:
        print("[No new reviews since last run.]", file=sys.stderr)
        return

    seen.update(emitted_ids)
    save_cache(cache_file, seen)
    print(f"[{len(emitted_ids)} new review(s). Cache updated.]", file=sys.stderr)


if __name__ == "__main__":
    main()
