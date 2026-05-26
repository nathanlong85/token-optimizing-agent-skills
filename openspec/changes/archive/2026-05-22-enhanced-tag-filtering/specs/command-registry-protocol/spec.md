## MODIFIED Requirements

### Requirement: Pre-command registry consultation

Before running or suggesting any shell command -- and before retrying a command after one failure -- an agent operating under the command-registry skill SHALL consult the command registries present on the system. The agent MUST check the project registry at `.agents/rules/local/command-registry/` first (if present) and the global registry at `~/.agents/rules/command-registry/` (or `$CREG_GLOBAL_PATH` if set) second. When both registries contain entries that match, the project entry wins. For exact id or keyword lookup, the agent MAY use grep, ripgrep, or `creg search`; for precise tag lookup, the agent SHOULD use `creg search --tags`, `creg search --any-tags`, or `creg search --exclude-tags` rather than raw substring search.

#### Scenario: Fresh command, single registry

- **WHEN** the agent is about to run a shell command and only the project registry is present
- **THEN** the agent reads `.agents/rules/local/command-registry/index.md`, identifies the relevant topic file from the routing table, and searches that topic file for a matching `## snake_case_id`, tag, or keyword before deciding on the final command

#### Scenario: Both registries present, project wins

- **WHEN** the agent finds matching entries with the same `id` in both project and global registries
- **THEN** the agent uses the project entry's `verified` / `template` and ignores the global entry

#### Scenario: Tag lookup uses structured filtering

- **WHEN** the agent needs an OpenSpec command and knows the lookup tags `openspec` and `status`
- **THEN** the agent uses `creg search --tags openspec,status` or an equivalent exact tag filter before falling back to keyword search

#### Scenario: Retry after failure

- **WHEN** the agent's previous shell command failed and it is considering a variation
- **THEN** the agent consults the registries again before issuing the retry, specifically scanning for an `anti_patterns` bullet that explains why the failed form fails

### Requirement: Token-efficient registry reads

When consulting a registry topic file, the agent SHALL search for the relevant section before reading the file in full. The agent MUST use grep, ripgrep, `creg search`, or another search mechanism to locate the target `## snake_case_id`, exact tag match, or keyword and read only the matched section (from the `##` line through the line before the next `##` or end-of-file). When tag logic requires AND, OR, or exclusion semantics, the agent SHOULD prefer `creg search --tags`, `creg search --any-tags`, or `creg search --exclude-tags` so it does not load unrelated entries.

#### Scenario: Search-first read

- **WHEN** a topic file contains many entries and the agent is looking for a specific command shape
- **THEN** the agent searches for the entry by id, exact tag filter, or keyword and opens only that section, rather than loading the entire topic file into context

#### Scenario: Multi-tag search avoids unrelated reads

- **WHEN** a registry contains many entries tagged `openspec` but only one also tagged `status`
- **THEN** the agent uses an exact multi-tag filter to identify the status entry before reading the matched section

### Requirement: Canonical activation snippet

The skill SHALL ship a single canonical activation snippet that users inject into agent rules files. The snippet MUST be scope-agnostic -- referencing both the project and global registry paths with "if present" guards -- so it works correctly regardless of which registries are installed and does not require updates when a registry is added later. The snippet MUST instruct agents to use structured `creg search --tags` filtering when they need precise tag matching.

#### Scenario: Snippet referenced from a Claude rules file

- **WHEN** a user runs `creg inject CLAUDE.md`
- **THEN** the snippet is appended to CLAUDE.md as plain markdown, and on subsequent sessions Claude reads CLAUDE.md, internalizes the protocol, and consults whichever registries exist before running shell commands

#### Scenario: Snippet referenced from a Cursor rules file

- **WHEN** a user runs `creg inject .cursor/rules/creg.mdc`
- **THEN** the snippet is written with YAML frontmatter containing `alwaysApply: true`, so Cursor loads it on every interaction

#### Scenario: Snippet includes tag filtering guidance

- **WHEN** a user injects the activation snippet
- **THEN** the snippet tells agents to use `creg search --tags <tag1>[,<tag2>]` for precise tag filtering instead of relying only on raw grep matching
