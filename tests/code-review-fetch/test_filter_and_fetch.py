"""Tests for review-state filtering and inline-comment fetch gating."""
import io
import json
import sys
import os
import unittest
from contextlib import redirect_stdout, redirect_stderr
from unittest.mock import patch, call
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../../skills/code-review-fetch/scripts"))

import fetch


def _review(rid, state, login="alice"):
    return {
        "id": rid,
        "state": state,
        "submitted_at": "2026-05-18T10:00:00Z",
        "body": "",
        "user": {"login": login},
    }


def _comment(cid, review_id, path="foo.py", line=1, body="fix this"):
    return {
        "id": cid,
        "pull_request_review_id": review_id,
        "path": path,
        "line": line,
        "original_line": line,
        "body": body,
    }


CODERABBIT = fetch.CODERABBIT_LOGIN


class TestStateFiltering(unittest.TestCase):
    def test_approved_dropped(self):
        reviews = [_review(1, "APPROVED"), _review(2, "CHANGES_REQUESTED")]
        kept = [r for r in reviews if r["state"] not in fetch.SKIP_STATES]
        self.assertEqual([r["id"] for r in kept], [2])

    def test_dismissed_dropped(self):
        reviews = [_review(1, "DISMISSED"), _review(2, "COMMENTED")]
        kept = [r for r in reviews if r["state"] not in fetch.SKIP_STATES]
        self.assertEqual([r["id"] for r in kept], [2])

    def test_pending_dropped(self):
        reviews = [_review(1, "PENDING"), _review(2, "CHANGES_REQUESTED")]
        kept = [r for r in reviews if r["state"] not in fetch.SKIP_STATES]
        self.assertEqual([r["id"] for r in kept], [2])

    def test_all_skip_states_defined(self):
        self.assertEqual(fetch.SKIP_STATES, {"APPROVED", "DISMISSED", "PENDING"})


class TestInlineCommentFetchGating(unittest.TestCase):
    """Inline comments fetched once for human reviews; not at all for CodeRabbit-only."""

    def _run_main(self, reviews, inline_comments=None, extra_api=None):
        """Drive main() with mocked gh_api; return stdout lines."""
        import tempfile, pathlib
        with tempfile.TemporaryDirectory() as tmp:
            orig_cache = fetch.CACHE_DIR
            fetch.CACHE_DIR = pathlib.Path(tmp)

            call_log = []

            def fake_gh_api(path, host, jq=None):
                call_log.append(path)
                if "reviews" in path:
                    return reviews
                if "comments" in path:
                    return inline_comments or []
                return extra_api(path) if extra_api else []

            def fake_resolve(*_):
                return "github.com", "owner", "repo"

            buf = io.StringIO()
            with patch.object(fetch, "gh_api", side_effect=fake_gh_api), \
                 patch.object(fetch, "resolve_context", side_effect=fake_resolve), \
                 patch("sys.argv", ["fetch.py", "1"]), \
                 redirect_stdout(buf):
                fetch.main()

            fetch.CACHE_DIR = orig_cache
            return buf.getvalue(), call_log

    def test_human_reviews_trigger_one_inline_fetch(self):
        reviews = [_review(10, "CHANGES_REQUESTED", "alice")]
        comments = [_comment(1, 10, body="please fix")]
        _, calls = self._run_main(reviews, comments)
        comment_calls = [c for c in calls if "comments" in c]
        self.assertEqual(len(comment_calls), 1)

    def test_coderabbit_only_skips_inline_fetch(self):
        cr_body = """
<details>
<summary>🤖 Prompt for all review comments with AI agents</summary>

```unknown
Fix the bug at line 5.
```

</details>
"""
        reviews = [dict(_review(10, "CHANGES_REQUESTED", CODERABBIT), body=cr_body)]
        _, calls = self._run_main(reviews)
        comment_calls = [c for c in calls if "comments" in c]
        self.assertEqual(len(comment_calls), 0)

    def test_mixed_reviews_one_inline_fetch(self):
        cr_body = """
<details>
<summary>🤖 Prompt for all review comments with AI agents</summary>

```unknown
Fix at line 5.
```

</details>
"""
        reviews = [
            dict(_review(10, "CHANGES_REQUESTED", CODERABBIT), body=cr_body),
            _review(11, "CHANGES_REQUESTED", "bob"),
        ]
        comments = [_comment(1, 11, body="nit")]
        _, calls = self._run_main(reviews, comments)
        comment_calls = [c for c in calls if "comments" in c]
        self.assertEqual(len(comment_calls), 1)


class TestStdoutStderr(unittest.TestCase):
    def _run_main_with_channels(self, reviews, inline_comments=None):
        import tempfile, pathlib
        with tempfile.TemporaryDirectory() as tmp:
            orig_cache = fetch.CACHE_DIR
            fetch.CACHE_DIR = pathlib.Path(tmp)

            def fake_gh_api(path, host, jq=None):
                if "reviews" in path:
                    return reviews
                return inline_comments or []

            def fake_resolve(*_):
                return "github.com", "owner", "repo"

            out_buf = io.StringIO()
            err_buf = io.StringIO()
            with patch.object(fetch, "gh_api", side_effect=fake_gh_api), \
                 patch.object(fetch, "resolve_context", side_effect=fake_resolve), \
                 patch("sys.argv", ["fetch.py", "1"]), \
                 redirect_stdout(out_buf), redirect_stderr(err_buf):
                fetch.main()

            fetch.CACHE_DIR = orig_cache
            return out_buf.getvalue(), err_buf.getvalue()

    def test_no_new_reviews_goes_to_stderr(self):
        out, err = self._run_main_with_channels([])
        self.assertIn("No new reviews", err)
        self.assertEqual(out, "")

    def test_coderabbit_fallback_warning_goes_to_stderr(self):
        reviews = [dict(_review(10, "CHANGES_REQUESTED", CODERABBIT), body="plain body no structure")]
        out, err = self._run_main_with_channels(reviews)
        self.assertIn("raw body", err)
        self.assertNotIn("raw body", out)

    def test_review_content_goes_to_stdout(self):
        cr_body = """
<details>
<summary>🤖 Prompt for all review comments with AI agents</summary>

```unknown
Actionable finding here.
```

</details>
"""
        reviews = [dict(_review(10, "CHANGES_REQUESTED", CODERABBIT), body=cr_body)]
        out, err = self._run_main_with_channels(reviews)
        self.assertIn("Actionable finding here", out)
        self.assertIn("=== CodeRabbit Review ===", out)
        self.assertNotIn("CodeRabbit Review #10", out)
        self.assertIn("Cache updated", err)


class TestCompactMode(unittest.TestCase):
    def _run_compact(self, reviews, inline_comments=None):
        import tempfile, pathlib
        with tempfile.TemporaryDirectory() as tmp:
            orig_cache = fetch.CACHE_DIR
            fetch.CACHE_DIR = pathlib.Path(tmp)

            def fake_gh_api(path, host, jq=None):
                if "reviews" in path:
                    return reviews
                return inline_comments or []

            def fake_resolve(*_):
                return "github.com", "owner", "repo"

            out_buf = io.StringIO()
            err_buf = io.StringIO()
            cache_before = set(
                (pathlib.Path(tmp) / f).stat().st_mtime
                for f in pathlib.Path(tmp).iterdir()
            ) if pathlib.Path(tmp).exists() else set()

            with patch.object(fetch, "gh_api", side_effect=fake_gh_api), \
                 patch.object(fetch, "resolve_context", side_effect=fake_resolve), \
                 patch("sys.argv", ["fetch.py", "1", "--compact"]), \
                 redirect_stdout(out_buf), redirect_stderr(err_buf):
                fetch.main()

            cache_files_after = {
                path.name: path.read_text()
                for path in pathlib.Path(tmp).iterdir()
                if path.is_file()
            }
            fetch.CACHE_DIR = orig_cache
            return out_buf.getvalue(), err_buf.getvalue(), cache_files_after

    def test_compact_summary_format(self):
        reviews = [
            _review(1, "CHANGES_REQUESTED", "alice"),
            _review(2, "CHANGES_REQUESTED", CODERABBIT),
        ]
        comments = [
            _comment(10, 1, path="app.py", body="fix this"),
            _comment(11, 1, path="utils.py", body="clean up"),
            _comment(12, 2, path="app.py", body="nit"),
        ]
        out, err, _ = self._run_compact(reviews, comments)
        self.assertIn("2 new review(s)", out)
        self.assertIn("alice", out)
        self.assertIn(CODERABBIT, out)
        self.assertIn("Files with comments:", out)
        self.assertIn("app.py", out)
        self.assertIn("utils.py", out)
        self.assertIn("Cache updated", err)

    def test_compact_no_new_reviews(self):
        out, err, _ = self._run_compact([])
        self.assertEqual(out, "")
        self.assertIn("No new reviews", err)

    def test_compact_updates_cache(self):
        reviews = [_review(1, "CHANGES_REQUESTED", "alice")]
        comments = [_comment(10, 1, path="app.py", body="fix")]
        _, _, cache_files = self._run_compact(reviews, comments)
        self.assertEqual(len(cache_files), 1, "compact mode should write cache for dedupe")
        cache_data = json.loads(next(iter(cache_files.values())))
        self.assertEqual(cache_data.get("seen_review_ids"), [1])


if __name__ == "__main__":
    unittest.main()
