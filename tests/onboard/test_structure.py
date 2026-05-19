"""Validation checks for onboard skill packaging and key instructions."""

import os
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]


class TestOnboardSkillStructure(unittest.TestCase):
    def test_required_files_exist(self):
        required = [
            REPO_ROOT / "skills/onboard/SKILL.md",
            REPO_ROOT / "skills/onboard/references/jira.md",
            REPO_ROOT / "skills/onboard/references/asana.md",
            REPO_ROOT / "skills/onboard/references/gh-issue.md",
            REPO_ROOT / "skills/onboard/references/file.md",
            REPO_ROOT / "skills/onboard/references/url.md",
            REPO_ROOT / "skills/onboard/references/reply.md",
            REPO_ROOT / "skills/onboard/evals/evals.json",
            REPO_ROOT / "skills/onboard-jira/SKILL.md",
        ]
        for path in required:
            self.assertTrue(path.exists(), f"Missing required file: {path}")

    def test_frontmatter_names_and_explicit_invocation(self):
        onboard = (REPO_ROOT / "skills/onboard/SKILL.md").read_text(encoding="utf-8")
        wrapper = (REPO_ROOT / "skills/onboard-jira/SKILL.md").read_text(encoding="utf-8")

        self.assertIn("name: onboard", onboard)
        self.assertIn("name: onboard-jira", wrapper)
        self.assertIn("# /onboard", onboard)
        self.assertIn("# /onboard-jira", wrapper)

    def test_wait_for_go_contract_present(self):
        onboard = (REPO_ROOT / "skills/onboard/SKILL.md").read_text(encoding="utf-8")
        self.assertIn("Do not implement", onboard)
        self.assertIn("explicitly says to start", onboard)

    def test_reply_contract_keywords(self):
        reply = (REPO_ROOT / "skills/onboard/references/reply.md").read_text(encoding="utf-8")
        self.assertIn("Acknowledgment", reply)
        self.assertIn("Summary", reply)
        self.assertIn("Questions / concerns", reply)
        self.assertIn("Explicit wait-for-go", reply)


if __name__ == "__main__":
    unittest.main()
