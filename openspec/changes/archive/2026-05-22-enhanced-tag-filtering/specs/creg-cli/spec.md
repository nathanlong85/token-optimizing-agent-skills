## ADDED Requirements

### Requirement: `creg tags` inventories registry tags

The `creg tags` subcommand SHALL print the tag vocabulary used by the target registry. It MUST accept `-g` to target the global registry and `--all` to include both project and global registries. It MUST support `--counts` to include per-tag usage counts and `--untagged` to list entries that do not contain any tags.

#### Scenario: List tags in project registry

- **WHEN** a user runs `creg tags` and the project registry contains entries tagged `docker`, `logs`, and `openspec`
- **THEN** the command prints each distinct tag once in sorted order

#### Scenario: List tag counts

- **WHEN** a user runs `creg tags --counts`
- **THEN** the command prints each distinct tag with the number of entries using that tag

#### Scenario: List untagged entries

- **WHEN** a user runs `creg tags --untagged`
- **THEN** the command prints the topic/id for entries that have no tags

### Requirement: `creg upgrade-tags` migrates legacy tag syntax

The `creg upgrade-tags` subcommand SHALL rewrite legacy inline tag strings into the canonical bulleted tag list format. It MUST accept `-g` to target the global registry and `--all` to include both project and global registries. It MUST support `--dry-run` to report affected files and entry IDs without modifying files. Running it against a registry that already uses canonical tags MUST be a no-op.

#### Scenario: Dry-run reports legacy tags

- **WHEN** an entry contains `tags: docker logs` and a user runs `creg upgrade-tags --dry-run`
- **THEN** the command reports that the entry would be rewritten and exits without modifying the registry

#### Scenario: Migration rewrites inline tags

- **WHEN** an entry contains `tags: docker logs` and a user runs `creg upgrade-tags`
- **THEN** the entry is rewritten with `tags:` followed by `- docker` and `- logs`

#### Scenario: Migration is idempotent

- **WHEN** every tagged entry already uses canonical bulleted tags
- **THEN** `creg upgrade-tags` exits successfully and reports that no changes were needed

## MODIFIED Requirements

### Requirement: `creg add` writes new entries with validation

The `creg add <topic> <id>` subcommand SHALL accept the entry fields as named flags (`--intent`, `--tags`, `--verified`, `--template`, `--variant`, `--anti-pattern`) and write a new entry to the specified topic file. The subcommand MUST validate the entry schema, refuse duplicate `id`s across the target registry, create the topic file and update the index routing table when the topic does not yet exist, and insert the entry at its A-Z sorted position. When `--tags` is provided, `creg add` MUST parse comma-separated and/or whitespace-separated tag input, validate each tag token, remove duplicates, and write tags using the canonical bulleted list format.

#### Scenario: Add to existing topic file

- **WHEN** `git_github.md` exists and an agent runs `creg add git_github pr_review_comments --intent "List review comments on a PR" --verified "gh api repos/{{owner}}/{{repo}}/pulls/{{pr}}/comments"`
- **THEN** the entry is inserted at its sorted position in `git_github.md` and the operation prints `Command registry: added pr_review_comments`

#### Scenario: Add creates a new topic file

- **WHEN** no `docker.md` file exists and an agent runs `creg add docker docker_compose_up ...`
- **THEN** `docker.md` is created with the new entry, and `index.md`'s routing table gains a row pointing at `docker.md`

#### Scenario: Add writes canonical tags

- **WHEN** an agent runs `creg add docker docker_logs --intent "Stream logs" --tags "docker,logs debugging" --template "docker logs -f {{container}}"`
- **THEN** the resulting entry contains `tags:` followed by bullets for `docker`, `logs`, and `debugging`

#### Scenario: Invalid tag rejected

- **WHEN** an agent runs `creg add docker docker_logs --intent "Stream logs" --tags "Docker Logs" --template "docker logs -f {{container}}"`
- **THEN** the command fails with a clear message that tags must be lowercase alphanumeric hyphenated tokens

#### Scenario: Multiple --anti-pattern flags accepted

- **WHEN** `creg add` is invoked with `--anti-pattern "foo"` and `--anti-pattern "bar"`
- **THEN** the resulting entry contains a bulleted `anti_patterns:` list with both items

### Requirement: Read subcommands

The CLI SHALL support `creg search <keyword>`, `creg show <id>`, and `creg list` for reading registry contents. `creg search` MUST match against `id`, `tags:`, `intent:`, and the contents of `verified:` / `template:` fields for keyword searches. `creg search` MUST also support `--tags <tags>` for AND tag filtering, `--any-tags <tags>` for OR tag filtering, and `--exclude-tags <tags>` for excluding entries by tag. Tag filters MUST use exact tag matches against both canonical list tags and legacy inline tags. All three commands SHALL accept `-g` to target the global registry and `--all` to search/list across both registries simultaneously.

#### Scenario: Search across project and global

- **WHEN** a user runs `creg search "jenkins" --all` and matching entries exist in both registries
- **THEN** both sets of matches are printed with a header indicating which registry each match came from

#### Scenario: Search requires all requested tags

- **WHEN** a user runs `creg search --tags openspec,status` and only one entry has both tags
- **THEN** only that entry is printed

#### Scenario: Search matches any requested tag

- **WHEN** a user runs `creg search --any-tags docker,kubernetes`
- **THEN** entries with either `docker` or `kubernetes` are printed

#### Scenario: Search excludes matching tags

- **WHEN** a user runs `creg search --tags deploy --exclude-tags deprecated`
- **THEN** entries tagged `deploy` are printed unless they are also tagged `deprecated`

#### Scenario: Keyword combines with tag filter

- **WHEN** a user runs `creg search --tags openspec "status"`
- **THEN** only entries that match the `openspec` tag and the `status` keyword are printed

#### Scenario: Show single entry

- **WHEN** a user runs `creg show ci_monitor_pr`
- **THEN** the full `## ci_monitor_pr` section (from `##` through the line before the next `##`) is printed

### Requirement: `creg validate` checks format and consistency

The `creg validate` subcommand SHALL inspect every entry in the target registry and report: missing required fields, entries with neither `verified:` nor `template:`, duplicate `id`s across topic files, malformed tag tokens, duplicate tags within one entry, unsupported tag syntax, topic files not listed in `index.md`'s routing table, and routing-table rows pointing at non-existent files. The subcommand MUST exit with status 0 when no issues are found and a non-zero status when issues are reported. Legacy inline tag syntax MUST remain valid for compatibility, but the validator MUST report a warning that `creg upgrade-tags` can normalize it.

#### Scenario: Clean registry validates

- **WHEN** every entry has a valid schema, no duplicates exist, canonical tags are well-formed, and the routing table is consistent
- **THEN** `creg validate` exits with status 0 and prints a brief confirmation

#### Scenario: Duplicate tag detected

- **WHEN** an entry contains the tag `docker` twice
- **THEN** `creg validate` reports the duplicate tag and exits with non-zero status

#### Scenario: Malformed tag detected

- **WHEN** an entry contains a tag `Docker Logs`
- **THEN** `creg validate` reports the malformed tag and exits with non-zero status

#### Scenario: Legacy inline tag warning

- **WHEN** an entry contains `tags: docker logs`
- **THEN** `creg validate` reports a warning recommending `creg upgrade-tags` without treating the legacy syntax itself as an error

#### Scenario: Drift detected

- **WHEN** a topic file was created manually but `index.md`'s routing table was not updated
- **THEN** `creg validate` reports the drift and exits with non-zero status
