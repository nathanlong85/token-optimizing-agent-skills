import unittest
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(__file__)), "scripts"))

from fetch import group_inline_comments, render_human_review

COMMENTS = [
    {"id": 1, "pull_request_review_id": 100, "path": "src/auth.py", "line": 42, "original_line": 40, "body": "Token expiry bug"},
    {"id": 2, "pull_request_review_id": 100, "path": "src/utils.py", "line": None, "original_line": 17, "body": "Naming issue"},
    {"id": 3, "pull_request_review_id": 101, "path": "README.md", "line": 5, "original_line": 5, "body": "Typo here"},
]


class TestGroupInlineComments(unittest.TestCase):
    def test_groups_by_review_id(self):
        grouped = group_inline_comments(COMMENTS)
        self.assertEqual(len(grouped[100]), 2)
        self.assertEqual(len(grouped[101]), 1)

    def test_skips_comments_without_review_id(self):
        comments = [{"id": 99, "pull_request_review_id": None, "path": "x.py", "line": 1, "body": "orphan"}]
        grouped = group_inline_comments(comments)
        self.assertEqual(grouped, {})

    def test_empty_input(self):
        self.assertEqual(group_inline_comments([]), {})


class TestRenderHumanReview(unittest.TestCase):
    def test_renders_comments(self):
        grouped = group_inline_comments(COMMENTS)
        result = render_human_review(100, grouped)
        self.assertIn("src/auth.py", result)
        self.assertIn("Around line 42", result)  # prefers `line` over `original_line`
        self.assertIn("Token expiry bug", result)

    def test_falls_back_to_original_line(self):
        grouped = group_inline_comments(COMMENTS)
        result = render_human_review(100, grouped)
        # second comment has line=None, should use original_line=17
        self.assertIn("Around line 17", result)

    def test_returns_none_for_empty_group(self):
        grouped = group_inline_comments(COMMENTS)
        result = render_human_review(999, grouped)
        self.assertIsNone(result)

    def test_skips_empty_group_key(self):
        result = render_human_review(100, {})
        self.assertIsNone(result)


if __name__ == "__main__":
    unittest.main()
