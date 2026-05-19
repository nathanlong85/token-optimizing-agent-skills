---
name: onboard
description: >
  Use when the user wants to get up to speed before implementation, especially
  when they invoke /onboard or provide Jira keys, Asana IDs/URLs, GitHub issue
  references, file paths, URLs, or pasted task descriptions. Loads source
  context, summarizes goals and risks, asks clarifying questions, and waits for
  explicit start approval before any implementation.
---

# /onboard

Onboard context before coding. This skill is read-first and implementation-gated.

## Hard boundary

Do not implement, edit files, run code-changing commands, or mutate external systems until the user explicitly says to start (for example: `start`, `go`, `proceed`, `begin`).

## 1) Parse input into sources + instructions

Split the user message into:

1. **Sources** (0..N)
2. **Inline instructions** (optional trailing guidance)

### Supported source forms

- Typed source: `jira:<value>`, `asana:<value>`, `gh:<value>`, `file:<path>`, `url:<url>`
- Jira shorthand: `PROJ-123` (single-source mode only)
- Full URL: Jira, Asana, GitHub Issue, or generic webpage
- Existing local path: markdown/text/pdf/handover files
- Pasted task description block

### Multi-source rules

- Source cap: **maximum 3 sources** in one onboarding run.
- If there is more than one source and at least one source type is ambiguous, require typed prefixes.
- If cap is exceeded, ask the user to reduce the list before loading.

### Inline instructions rules

Treat trailing natural language outside parsed source tokens as run-level instructions.

Examples:
- `/onboard jira:PROJ-123 asana:1213994804762894 Please focus on acceptance criteria only`
- `/onboard-jira PROJ-123 Please run /opsx-new after onboarding`

`instructions:` may be used as an explicit delimiter when helpful:
- `/onboard jira:PROJ-123 asana:121 instructions: skip parent epic and keep summary brief`

If no usable source is present, ask the user to provide one or more valid sources.

## 2) Route each source

For each parsed source, load the matching reference file:

- Jira -> `references/jira.md`
- Asana -> `references/asana.md`
- GitHub issue -> `references/gh-issue.md`
- Local file -> `references/file.md`
- Generic URL -> `references/url.md`

For source-specific loading details, follow those reference files instead of duplicating logic in this file.

## 3) Build a labeled context bundle

After loading each source, keep sections clearly labeled (for example, `Jira: PROJ-123`, `Asana: 121399...`).

When inline instructions constrain scope (for example, "skip parent epic"), apply them while loading and analyzing.

## 4) Analyze before replying

Analyze the bundled context for:

- ambiguities and missing acceptance criteria
- sequencing and dependency risks
- architecture or integration concerns
- likely edge cases and failure modes
- conflicts between sources

If no concerns exist, explicitly say `No concerns.`

## 5) Reply format

Follow `references/reply.md` for the exact output contract.

At minimum include, in order:

1. Acknowledgment of source(s) read
2. 2-4 sentence summary
3. Numbered questions/concerns (or `No concerns.`)
4. Readiness statement
5. Explicit wait-for-go statement

## 6) Next-message behavior

- If user answers questions only: update understanding and keep waiting.
- If user clarifies scope only: acknowledge updates and keep waiting.
- If user explicitly starts implementation: onboarding is complete, then proceed with implementation workflow.
