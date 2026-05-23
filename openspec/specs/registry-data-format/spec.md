# registry-data-format Specification

## Purpose

TBD - created as part of the `command-registry` change.

## Requirements

### Requirement: Registry directory layout

A command registry SHALL be a directory containing an `index.md` file and zero or more topic markdown files. The project registry MUST live at `.agents/rules/local/command-registry/` relative to the repository root. The global registry MUST live at `~/.agents/rules/command-registry/` by default, with the `CREG_GLOBAL_PATH` environment variable overriding the default location.

#### Scenario: Project registry discovery

- **WHEN** a tool needs to locate the project registry from inside a checkout
- **THEN** the tool walks up the directory tree from the current working directory until it finds `.agents/rules/local/command-registry/`, using the same strategy git uses to find `.git`

#### Scenario: Global registry override

- **WHEN** the environment variable `CREG_GLOBAL_PATH` is set to `/Users/alice/Dropbox/command-registry/`
- **THEN** the global registry is loaded from that path instead of `~/.agents/rules/command-registry/`

### Requirement: index.md structure

Every registry directory SHALL contain an `index.md` file at its root. The file MUST contain three sections in order: a **Route** routing table mapping task descriptions to topic file names, a **Rules** section describing when and how agents consult the registry, and an **Entry format** section describing the schema for `## snake_case_id` sections in topic files. The routing table starts empty on `creg init` and is populated as topic files are created.

#### Scenario: Fresh registry has empty routing table

- **WHEN** a user runs `creg init` to create a new registry
- **THEN** `index.md` is created with the Route table header but no rows, plus populated Rules and Entry format sections

#### Scenario: Routing table updated when topic file is created

- **WHEN** an agent runs `creg add <new-topic> <id> ...` and `<new-topic>` does not yet exist
- **THEN** the topic file is created, and a new row is inserted into the Route table in `index.md` linking the task description to the new file

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

### Requirement: A-Z sort within topic files

Entries within a single topic file SHALL be sorted alphabetically by `id`. `creg add` MUST insert new entries at the correct sorted position.

#### Scenario: Insertion preserves sort order

- **WHEN** a topic file contains entries `## apple_one`, `## carrot_two`, `## eggplant_three` and an agent runs `creg add` for `## broccoli_four`
- **THEN** the new entry is inserted between `## apple_one` and `## carrot_two`

### Requirement: Project vs global classification

The activation snippet shipped with the skill SHALL include an explicit classification rule for new commands: commands containing hardcoded project paths, hostnames, organization/repo names, or project-specific scripts (such as `bin/dcdev`) belong in the project registry; commands that are generic across repositories and parameterize variable values with `{{placeholders}}` belong in the global registry.

#### Scenario: Project-specific command classified to project

- **WHEN** the command being added is `GH_HOST=github.example.com gh api repos/prod-tools/service-portal/pulls/{{pr}}/reviews`
- **THEN** the agent invokes `creg add` without the `-g` flag, writing to the project registry

#### Scenario: Generic command classified to global

- **WHEN** the command being added is `gh api repos/{{owner}}/{{repo}}/pulls/{{pr}}/reviews`
- **THEN** the agent invokes `creg add ... -g`, writing to the global registry

### Requirement: Deduplication across topic files

A registry SHALL contain at most one entry with any given `id` across all of its topic files. `creg add` MUST fail with a clear error when an `id` already exists in another topic file of the target registry, and SHOULD direct the user toward `creg move` or extending the existing entry.

#### Scenario: Duplicate id rejected

- **WHEN** `git_github.md` already contains `## pr_view` and an agent runs `creg add other pr_view ...`
- **THEN** the command fails with a message indicating where the existing `pr_view` entry lives and suggesting `creg move` or extending the existing entry

### Requirement: Portable registry bundle format

A portable command-registry export SHALL be a markdown document using the `creg-bundle-v1` format. The document MUST start with a level-1 heading, include a `format: creg-bundle-v1` metadata line before any entry, and represent each exported entry as a level-2 heading of the form `## <topic>/<id>`. The entry body MUST use the same field syntax as topic-file entries. Importers MUST reject bundle entries whose topic or id cannot be represented safely in registry topic files.

#### Scenario: Bundle contains one entry

- **WHEN** a bundle contains `format: creg-bundle-v1`, a heading `## docker/docker_logs`, and an entry body with `intent:` and `template:`
- **THEN** the bundle identifies one importable entry with topic `docker` and id `docker_logs`

#### Scenario: Bundle preserves entry fields

- **WHEN** an exported entry contains `tags:`, `verified:`, `template:`, `variants:`, and `anti_patterns:`
- **THEN** the bundle preserves those fields using the same syntax accepted by registry topic files

#### Scenario: Invalid bundle heading rejected

- **WHEN** a bundle entry heading does not match `## <topic>/<id>`
- **THEN** import validation rejects the bundle with a clear message identifying the invalid heading

#### Scenario: Unsupported bundle format rejected

- **WHEN** a bundle does not contain `format: creg-bundle-v1`
- **THEN** import validation rejects the bundle without modifying any registry files
