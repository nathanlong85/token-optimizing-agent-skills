# command-registry-protocol Specification

## Purpose

TBD - created as part of the `command-registry` change.

## Requirements

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

### Requirement: Lookup priority within a matched entry

When the agent has located a matching entry, the agent SHALL prefer applying the entry's content in this priority order: (1) the exact `verified` command if it works without modification, (2) the `template` with `{{placeholders}}` filled in if the entry has one, (3) the closest match by `intent` if no exact verified or template applies. The agent MUST NOT improvise a fresh command shape when an entry exists.

#### Scenario: Verified command applies directly

- **WHEN** an entry has a `verified` field and the agent's task matches it without parameterization
- **THEN** the agent uses the verified command literally

#### Scenario: Template adaptation

- **WHEN** an entry has a `template` field with `{{placeholders}}` and the agent's task fits that shape
- **THEN** the agent substitutes values into the placeholders and runs the resulting command

### Requirement: Same-turn registry updates

When the agent discovers a working shell command that is not present in the registry, the agent SHALL record the command in the registry within the same turn using the `creg add` CLI. The agent MUST classify the command as project-specific or generic before writing, and MUST emit a one-line user-facing notification when the registry changes.

#### Scenario: Project-specific command recorded

- **WHEN** the agent successfully runs a command that contains a hardcoded project path, hostname, organization name, or project-specific script (e.g., `bin/dcdev`, `GH_HOST=github.example.com`, `service-portal`)
- **THEN** the agent runs `creg add <topic> <id> --intent "..." --verified "..." [other fields]` (no `-g` flag) and prints `Command registry: added <id>` to the user

#### Scenario: Generic command recorded globally

- **WHEN** the agent successfully runs a command that is generic across repos and uses `{{placeholders}}` for anything variable
- **THEN** the agent runs `creg add <topic> <id> ... -g` and prints `Command registry: added <id>` to the user

#### Scenario: Existing entry extension

- **WHEN** the agent discovers a new variant or anti-pattern related to an existing `## id`
- **THEN** the agent extends the existing entry (adding to `variants:` or `anti_patterns:`) rather than creating a near-duplicate section, and prints `Command registry: updated <id>` to the user

### Requirement: Conflict resolution between registry and project rules

When the registry and project rules appear to disagree, the agent SHALL apply the rule "registry wins for command shape; project rules win for policy." Command shape means the literal syntax, flags, and arguments of a working command. Policy means cross-cutting requirements like "always use Docker for specs" or "never push to main."

#### Scenario: Registry has verified syntax, project rules add a policy constraint

- **WHEN** the registry has a `verified` for `bundle exec rspec spec/foo_spec.rb` but project rules require all specs to run inside Docker
- **THEN** the agent applies the policy (Docker) on top of the verified shape (rspec invocation), producing `bin/dcdev rspec spec/foo_spec.rb`

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

### Requirement: AI-assisted catch-all reclassification planning

When asked to reclassify command registry entries, an agent operating under the command-registry skill SHALL inspect catch-all topics such as `other.md` and produce a dry-run migration plan before making any registry changes. The plan MUST identify proposed topic files, entry IDs to move, rationale, confidence, entries left in place, and validation steps.

#### Scenario: Related commands proposed for new topic

- **WHEN** `other.md` contains three or more entries with a clear shared domain or command family
- **THEN** the agent proposes moving those entries into a named topic file and includes rationale and confidence for each proposed move

#### Scenario: Ambiguous entries remain in catch-all

- **WHEN** an entry does not clearly belong to a cluster or has low classification confidence
- **THEN** the agent leaves the entry in `other.md` and explains why it was not moved

### Requirement: Approval-gated reclassification execution

The agent SHALL NOT execute reclassification moves until the user approves the dry-run plan. After approval, the agent MUST use deterministic registry operations such as `creg move` where available and MUST run `creg validate` after changes.

#### Scenario: User approves dry-run plan

- **WHEN** the user approves a proposed reclassification plan
- **THEN** the agent executes the approved moves with `creg move` where possible and runs `creg validate` for the affected registry

#### Scenario: User has not approved

- **WHEN** a dry-run plan has been produced but the user has not approved it
- **THEN** the agent makes no registry file changes

### Requirement: Conservative reclassification thresholds

The agent SHALL default to conservative clustering when proposing reclassification. A new topic SHOULD normally require at least three related entries. The agent MUST NOT move singleton entries out of `other.md` unless the user names a destination or explicitly requests aggressive cleanup.

#### Scenario: Two related entries found

- **WHEN** only two entries share a theme and the user has not requested aggressive cleanup
- **THEN** the agent may mention the possible grouping but leaves both entries in `other.md`

#### Scenario: User names singleton destination

- **WHEN** the user explicitly asks to move one specific entry to a named topic
- **THEN** the agent may include that singleton move in the approved execution plan

### Requirement: Scope-aware reclassification

During reclassification planning, the agent SHALL evaluate whether candidate entries belong in the project registry or the global registry. Cross-scope moves MUST be called out separately in the dry-run plan and require explicit user approval.

#### Scenario: Generic entry in project catch-all

- **WHEN** a catch-all project entry is generic across repositories and uses placeholders for variable values
- **THEN** the agent proposes moving or recreating it in the global registry and marks the move as cross-scope

#### Scenario: Project-specific entry in global catch-all

- **WHEN** a global catch-all entry contains hardcoded project paths, hostnames, org/repo names, or project-specific scripts
- **THEN** the agent proposes moving or recreating it in the project registry and marks the move as cross-scope
