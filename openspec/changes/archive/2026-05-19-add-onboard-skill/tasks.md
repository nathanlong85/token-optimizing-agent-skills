## 1. Skill Structure

- [x] 1.1 Create `skills/onboard/` with a spec-compliant `SKILL.md` using `name: onboard` and `disable-model-invocation: true`.
- [x] 1.2 Create `skills/onboard/references/` files for shared source behavior: `jira.md`, `asana.md`, `gh-issue.md`, `file.md`, `url.md`, and `reply.md`.
- [x] 1.3 Create `skills/onboard-jira/` as a thin wrapper skill with `name: onboard-jira` and `disable-model-invocation: true`.
- [x] 1.4 Add README documentation for installing and invoking `onboard` and `onboard-jira`.

## 2. Canonical Onboarding Workflow

- [x] 2.1 Port the existing personal onboard workflow into `skills/onboard/SKILL.md`, preserving summary, questions or concerns, readiness, and explicit wait behavior.
- [x] 2.2 Define the source parser rules for single-source shorthand, multi-source typed prefixes, URLs, file paths, pasted content, and ambiguous input.
- [x] 2.3 Define the multi-source cap and behavior when the cap is exceeded.
- [x] 2.4 Define inline instruction handling, including trailing instructions and optional `instructions:` delimiter examples.
- [x] 2.5 Ensure the workflow states that implementation, code edits, code-changing commands, and ticket mutations are forbidden until the user explicitly starts.

## 3. Source References

- [x] 3.1 Write `references/jira.md` with Jira key parsing, parent Epic default behavior, skip-parent overrides, and read-only fetch guidance while `jira-fetch` is deferred.
- [x] 3.2 Write `references/asana.md` with Asana ID/URL handling, preferred access paths, and authenticated-access fallback to pasted content.
- [x] 3.3 Write `references/gh-issue.md` with GitHub issue URL/ID handling and compact `gh` field-selection guidance.
- [x] 3.4 Write `references/file.md` with local text file, markdown file, and PDF handling guidance that avoids dumping large documents into context.
- [x] 3.5 Write `references/url.md` with host-based routing and generic webpage fallback behavior.
- [x] 3.6 Write `references/reply.md` with the required response template and examples for single-source and multi-source onboarding.

## 4. Thin Wrapper Skill

- [x] 4.1 Implement `skills/onboard-jira/SKILL.md` as a Jira-only entrypoint that delegates to `skills/onboard/` behavior.
- [x] 4.2 Document that `/onboard-jira PROJ-123` treats Jira as the implicit source type and still honors trailing inline instructions.
- [x] 4.3 Ensure the wrapper does not duplicate full source-loading or reply instructions beyond what is needed for reliable delegation.

## 5. Evals and Validation

- [x] 5.1 Add `skills/onboard/evals/evals.json` with realistic prompts for Jira shorthand, multi-source prefixes, Asana fallback, GitHub issue URL, local file path, pasted content, trailing instructions, and near-miss negatives.
- [x] 5.2 Add lightweight tests or validation checks for required files, frontmatter names, and key instruction phrases.
- [x] 5.3 Run `skills-ref validate ./skills/onboard` when available.
- [x] 5.4 Run `skills-ref validate ./skills/onboard-jira` when available.
- [x] 5.5 Run repo tests relevant to skill packaging and report any unavailable validators or skipped live-source checks.
