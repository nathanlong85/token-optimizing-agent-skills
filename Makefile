.PHONY: test test-command-registry test-code-review-fetch

test: test-command-registry test-code-review-fetch

test-command-registry:
	@for t in tests/command-registry/test_*.sh; do bash "$$t" || exit 1; done

test-code-review-fetch:
	pytest tests/code-review-fetch/
