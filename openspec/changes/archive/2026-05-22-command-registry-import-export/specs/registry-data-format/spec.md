## ADDED Requirements

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
