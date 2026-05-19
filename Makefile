.PHONY: test test-skills test-command-registry test-code-review-fetch test-onboard

test: test-skills test-command-registry test-code-review-fetch test-onboard

test-skills:
	agentskills validate ./skills/code-review-fetch
	agentskills validate ./skills/command-registry
	agentskills validate ./skills/onboard
	agentskills validate ./skills/onboard-jira

test-command-registry:
	@for t in tests/command-registry/test_*.sh; do bash "$$t" || exit 1; done

test-code-review-fetch:
	pytest tests/code-review-fetch/

test-onboard:
	pytest tests/onboard/
