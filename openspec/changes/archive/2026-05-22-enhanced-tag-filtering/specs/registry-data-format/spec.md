## MODIFIED Requirements

### Requirement: Topic file entry schema

Each entry in a topic file SHALL be introduced by a level-2 markdown heading of the form `## snake_case_id`. The `id` MUST be globally unique across all topic files within a single registry. Each entry MUST contain an `intent:` field on a single line. Each entry MAY contain `tags:`, `verified:`, `template:`, `variants:`, and `anti_patterns:` fields. `verified:` and `template:` are mutually optional but at least one MUST be present. `tags:`, when written by `creg`, MUST use a bulleted list of lowercase alphanumeric hyphenated tag tokens. Legacy inline tag strings MUST remain readable by CLI read, search, validation, and migration commands. `variants:` and `anti_patterns:`, when present, are bulleted lists.

#### Scenario: Minimal valid entry

- **WHEN** an entry has `## my_command`, `intent: Brief description`, and `verified: ls -la`
- **THEN** the entry passes schema validation

#### Scenario: Entry with canonical tags

- **WHEN** an entry has `tags:` followed by bullets `- docker` and `- logs`
- **THEN** the entry passes schema validation and the tags are available for exact tag filtering

#### Scenario: Legacy inline tags remain readable

- **WHEN** an existing entry has `tags: docker logs debugging`
- **THEN** CLI read and search commands treat the entry as having the tags `docker`, `logs`, and `debugging`

#### Scenario: Entry with template and anti-patterns

- **WHEN** an entry has `template: gh api repos/{{owner}}/{{repo}}/pulls/{{pr}}/reviews` and a bulleted `anti_patterns:` list explaining why `curl` fails
- **THEN** the entry passes schema validation and the anti_patterns are available to agents searching for this command shape

#### Scenario: Missing both verified and template fails validation

- **WHEN** an entry has `intent:` but no `verified:` and no `template:`
- **THEN** `creg validate` reports the entry as invalid with a clear message
