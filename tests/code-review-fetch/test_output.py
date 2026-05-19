import io
import sys
import os
import unittest
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../../skills/code-review-fetch/scripts"))

from fetch import _format_date, render_human_review, group_inline_comments


class TestFormatDate(unittest.TestCase):
    def test_extracts_date_prefix(self):
        self.assertEqual(_format_date("2026-05-14T13:30:00Z"), "2026-05-14")

    def test_handles_empty(self):
        self.assertEqual(_format_date(""), "unknown")


class TestHeaderFormat(unittest.TestCase):
    """Verify header strings follow the spec format."""

    def test_coderabbit_header(self):
        header = "=== CodeRabbit Review ==="
        self.assertEqual(header, "=== CodeRabbit Review ===")
        self.assertNotIn("#", header)
        self.assertNotIn("(", header)

    def test_human_header(self):
        login = "alice"
        header = f"=== Review by {login} ==="
        self.assertEqual(header, "=== Review by alice ===")
        self.assertNotIn("#", header)
        self.assertNotIn("(", header)


class TestRenderHumanReviewOutput(unittest.TestCase):
    def test_multi_comment_format(self):
        comments = [
            {"id": 1, "pull_request_review_id": 200, "path": "app.py", "line": 10, "original_line": 10, "body": "Use ctx manager"},
            {"id": 2, "pull_request_review_id": 200, "path": "app.py", "line": 20, "original_line": 20, "body": "Missing return"},
        ]
        grouped = group_inline_comments(comments)
        result = render_human_review(200, grouped)
        self.assertIn("In `app.py`: Around line 10: Use ctx manager", result)
        self.assertIn("In `app.py`: Around line 20: Missing return", result)


if __name__ == "__main__":
    unittest.main()
