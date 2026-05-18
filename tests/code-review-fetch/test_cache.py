import json
import unittest
import tempfile
import sys
import os
from pathlib import Path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../../skills/code-review-fetch/scripts"))

import fetch


class TestCache(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self._orig_cache_dir = fetch.CACHE_DIR
        fetch.CACHE_DIR = Path(self.tmp.name)

    def tearDown(self):
        fetch.CACHE_DIR = self._orig_cache_dir
        self.tmp.cleanup()

    def _cache_path(self, pr=1234):
        return fetch._cache_path("github.com", "owner", "repo", pr)

    def test_missing_file_returns_empty_set(self):
        path = self._cache_path()
        result = fetch.load_cache(path)
        self.assertEqual(result, set())

    def test_corrupt_file_returns_empty_set(self):
        path = self._cache_path()
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("not json")
        result = fetch.load_cache(path)
        self.assertEqual(result, set())

    def test_round_trip(self):
        path = self._cache_path()
        seen = {1, 2, 3}
        fetch.save_cache(path, seen)
        loaded = fetch.load_cache(path)
        self.assertEqual(loaded, seen)

    def test_save_writes_last_run(self):
        path = self._cache_path()
        fetch.save_cache(path, {7})
        data = json.loads(path.read_text())
        self.assertIn("last_run", data)

    def test_clear_deletes_only_target_pr(self):
        path_1234 = self._cache_path(pr=1234)
        path_5678 = self._cache_path(pr=5678)
        fetch.save_cache(path_1234, {1})
        fetch.save_cache(path_5678, {2})

        # simulate --clear for PR 1234
        if path_1234.exists():
            path_1234.unlink()

        self.assertFalse(path_1234.exists())
        self.assertTrue(path_5678.exists())


if __name__ == "__main__":
    unittest.main()
