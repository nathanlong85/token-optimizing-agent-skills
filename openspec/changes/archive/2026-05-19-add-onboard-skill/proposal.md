## Why

Agents need a repeatable way to get up to speed on a project or task before implementation starts, regardless of whether the context comes from Jira, Asana, GitHub issues, local files, URLs, or pasted instructions. The existing personal `onboard` skill proves the workflow, but it is too narrow, not installable from this repo, and does not yet follow the current Agent Skills structure for progressive disclosure, evals, and future source-specific fetchers.

## What Changes

- Add a canonical `onboard` skill under `skills/onboard/` for explicit onboarding before implementation.
- Support single-source shorthand (`PROJ-123`, full URLs, file paths, pasted text) and multi-source onboarding with required type prefixes when more than one source is supplied.
- Add thin source-specific skills such as `onboard-jira` that delegate to the canonical workflow while allowing ergonomic single-source invocation.
- Preserve the current wait-for-go contract: the skill reads, summarizes, identifies questions or concerns, and does not implement until the user explicitly starts.
- Use `references/` for source-specific loading instructions and `evals/evals.json` for trigger and output-quality iteration.
- Defer compact Jira data fetching to a future `jira-fetch` skill rather than embedding that fetcher in this change.

## Capabilities

### New Capabilities
- `task-onboarding`: Defines how an onboarding skill parses one or more task context sources, loads relevant source references, summarizes context, surfaces questions or concerns, and waits for explicit implementation approval.

### Modified Capabilities
- None.

## Impact

- Adds new skill directories under `skills/` and related eval fixtures.
- May add README entries describing the new onboarding skills and installation expectations via `skills`.
- Does not change existing `code-review-fetch` or `command-registry` behavior.
- Does not add Jira or Asana compact fetcher scripts in this change; those remain future source-specific skills.
