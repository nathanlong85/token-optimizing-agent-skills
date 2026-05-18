import unittest
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../../skills/code-review-fetch/scripts"))

from fetch import extract_coderabbit_content

PROMPT_BLOCK_BODY = """
<details>
<summary>🤖 Prompt for all review comments with AI agents</summary>

```unknown
Verify each finding against current code. Fix only still-valid issues.

file: src/auth.py, lines 42-45: token expiry uses < instead of <=
```

</details>
"""

NITPICK_ONLY_BODY = """
## Nitpick comments

Some nitpick feedback here.
No prompt block present.

## Other section

Other content.
"""

OUTSIDE_DIFF_BODY = """
## Comments outside of the diff area

This comment is outside the diff.
"""

BOTH_FALLBACK_SECTIONS = """
## Nitpick comments

Nitpick here.

## Comments outside of the diff area

Outside diff here.
"""

PLAIN_BODY = "This is a plain review body with no structured sections."


class TestExtractCoderabbitContent(unittest.TestCase):
    def test_extracts_prompt_block(self):
        result = extract_coderabbit_content(PROMPT_BLOCK_BODY, review_id=1)
        self.assertIn("token expiry uses < instead of <=", result)
        self.assertNotIn("```", result)

    def test_falls_back_to_nitpicks(self):
        import io
        from contextlib import redirect_stderr
        buf = io.StringIO()
        with redirect_stderr(buf):
            result = extract_coderabbit_content(NITPICK_ONLY_BODY, review_id=2)
        self.assertIn("nitpick feedback", result.lower())
        self.assertIn("warning", buf.getvalue().lower())
        self.assertIn("2", buf.getvalue())

    def test_falls_back_to_outside_diff(self):
        import io
        from contextlib import redirect_stderr
        buf = io.StringIO()
        with redirect_stderr(buf):
            result = extract_coderabbit_content(OUTSIDE_DIFF_BODY, review_id=3)
        self.assertIn("outside the diff", result.lower())

    def test_falls_back_to_both_sections(self):
        import io
        from contextlib import redirect_stderr
        buf = io.StringIO()
        with redirect_stderr(buf):
            result = extract_coderabbit_content(BOTH_FALLBACK_SECTIONS, review_id=4)
        self.assertIn("Nitpick here", result)
        self.assertIn("Outside diff here", result)

    def test_falls_back_to_raw_body(self):
        import io
        from contextlib import redirect_stderr
        buf = io.StringIO()
        with redirect_stderr(buf):
            result = extract_coderabbit_content(PLAIN_BODY, review_id=5)
        self.assertEqual(result, PLAIN_BODY.strip())
        self.assertIn("raw body", buf.getvalue().lower())


if __name__ == "__main__":
    unittest.main()
