"""Tests for resolve_context: short-circuit, inference, and error messaging."""
import io
import json
import subprocess
import sys
import os
import unittest
from contextlib import redirect_stderr
from unittest.mock import MagicMock, patch

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(__file__)), "scripts"))

from fetch import resolve_context


def _gh_view(owner="alice", name="myrepo", url="https://github.com"):
    m = MagicMock()
    m.stdout = json.dumps({"owner": {"login": owner}, "name": name, "url": url})
    return m


class TestResolveContextShortCircuit(unittest.TestCase):
    def test_both_provided_skips_gh(self):
        host, owner, repo_name = resolve_context("acme/widgets", "github.example.com")
        self.assertEqual(host, "github.example.com")
        self.assertEqual(owner, "acme")
        self.assertEqual(repo_name, "widgets")

    def test_both_provided_github_com(self):
        host, owner, repo_name = resolve_context("alice/myrepo", "github.com")
        self.assertEqual(host, "github.com")
        self.assertEqual(owner, "alice")
        self.assertEqual(repo_name, "myrepo")


class TestResolveContextInference(unittest.TestCase):
    def test_infers_github_com_from_url(self):
        with patch("subprocess.run", return_value=_gh_view("alice", "myrepo", "https://github.com")):
            host, owner, repo_name = resolve_context(None, None)
        self.assertEqual(host, "github.com")
        self.assertEqual(owner, "alice")
        self.assertEqual(repo_name, "myrepo")

    def test_infers_ghe_host_from_url(self):
        with patch("subprocess.run", return_value=_gh_view("acme", "widgets", "https://github.example.com")):
            host, owner, repo_name = resolve_context(None, None)
        self.assertEqual(host, "github.example.com")
        self.assertEqual(owner, "acme")
        self.assertEqual(repo_name, "widgets")

    def test_explicit_host_overrides_url(self):
        with patch("subprocess.run", return_value=_gh_view("alice", "myrepo", "https://github.example.com")):
            host, owner, repo_name = resolve_context(None, "github.com")
        self.assertEqual(host, "github.com")
        self.assertEqual(owner, "alice")

    def test_explicit_repo_overrides_gh_view_repo(self):
        with patch("subprocess.run", return_value=_gh_view("alice", "myrepo", "https://github.com")):
            host, owner, repo_name = resolve_context("other-org/other-repo", None)
        self.assertEqual(owner, "other-org")
        self.assertEqual(repo_name, "other-repo")
        self.assertEqual(host, "github.com")


class TestResolveContextErrors(unittest.TestCase):
    def test_missing_gh_names_provided_host(self):
        buf = io.StringIO()
        with redirect_stderr(buf):
            with patch("subprocess.run", side_effect=FileNotFoundError):
                with self.assertRaises(SystemExit) as cm:
                    resolve_context(None, "github.example.com")
        self.assertNotEqual(cm.exception.code, 0)
        self.assertIn("github.example.com", buf.getvalue())

    def test_missing_gh_defaults_to_github_com(self):
        buf = io.StringIO()
        with redirect_stderr(buf):
            with patch("subprocess.run", side_effect=FileNotFoundError):
                with self.assertRaises(SystemExit):
                    resolve_context(None, None)
        self.assertIn("github.com", buf.getvalue())

    def test_auth_failure_names_host(self):
        exc = subprocess.CalledProcessError(1, ["gh"])
        exc.stderr = "not authenticated"
        buf = io.StringIO()
        with redirect_stderr(buf):
            with patch("subprocess.run", side_effect=exc):
                with self.assertRaises(SystemExit) as cm:
                    resolve_context(None, "github.example.com")
        self.assertNotEqual(cm.exception.code, 0)
        stderr = buf.getvalue()
        self.assertIn("github.example.com", stderr)
        self.assertIn("auth status", stderr)

    def test_auth_failure_defaults_to_github_com(self):
        exc = subprocess.CalledProcessError(1, ["gh"])
        exc.stderr = "not authenticated"
        buf = io.StringIO()
        with redirect_stderr(buf):
            with patch("subprocess.run", side_effect=exc):
                with self.assertRaises(SystemExit):
                    resolve_context(None, None)
        self.assertIn("github.com", buf.getvalue())


if __name__ == "__main__":
    unittest.main()
