## ADDED Requirements

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
