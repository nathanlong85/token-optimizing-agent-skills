## ADDED Requirements

### Requirement: `creg export` writes portable bundles

The `creg export` subcommand SHALL write registry entries in the `creg-bundle-v1` markdown bundle format. With no scope flag it MUST export the project registry. With `-g` it MUST export the global registry. With `--all` it MUST export entries from both registries and include enough source-scope metadata for readers to understand where entries came from. It MUST support `--topic <topic>`, `--id <id>`, `--tags <tags>`, `--verified-only`, and `--output <file>` filters/options. When `--output` is absent, the bundle MUST be written to stdout.

#### Scenario: Export project registry to stdout

- **WHEN** a user runs `creg export` in a project registry containing `docker/docker_logs`
- **THEN** stdout contains a `creg-bundle-v1` bundle with an entry headed `## docker/docker_logs`

#### Scenario: Export to file

- **WHEN** a user runs `creg export --output commands.creg.md`
- **THEN** the bundle is written to `commands.creg.md` and normal stdout contains only a compact success message

#### Scenario: Export one topic

- **WHEN** a user runs `creg export --topic docker`
- **THEN** only entries from `docker.md` are included in the bundle

#### Scenario: Export one id

- **WHEN** a user runs `creg export --id docker_logs`
- **THEN** only the matching entry is included in the bundle

#### Scenario: Export by tags

- **WHEN** a user runs `creg export --tags docker,logs`
- **THEN** only entries matching all requested tags are included in the bundle

#### Scenario: Export verified entries only

- **WHEN** a user runs `creg export --verified-only`
- **THEN** entries without a `verified:` field are omitted from the bundle

### Requirement: `creg import` previews bundle imports by default

The `creg import <file>` subcommand SHALL parse and validate a `creg-bundle-v1` markdown bundle, compare its entries to the target registry, and print an import plan without modifying files by default. The plan MUST classify each bundle entry as `new`, `identical`, or `conflict`. With no scope flag it MUST target the project registry. With `-g` it MUST target the global registry.

#### Scenario: Import preview reports new entry

- **WHEN** a bundle contains `docker/docker_logs` and the target registry has no `docker_logs` entry
- **THEN** `creg import commands.creg.md` reports the entry as `new` and does not modify registry files

#### Scenario: Import preview reports identical entry

- **WHEN** a bundle contains an entry whose normalized body matches an existing target entry with the same id
- **THEN** `creg import commands.creg.md` reports the entry as `identical` and does not modify registry files

#### Scenario: Import preview reports conflict

- **WHEN** a bundle contains an entry whose id exists in the target registry but whose normalized body differs
- **THEN** `creg import commands.creg.md` reports the entry as `conflict` and does not modify registry files

#### Scenario: Invalid bundle does not modify files

- **WHEN** a bundle fails validation
- **THEN** `creg import commands.creg.md` exits non-zero and leaves registry files unchanged

### Requirement: `creg import --apply` writes non-conflicting entries

The `creg import <file> --apply` subcommand SHALL apply the validated import plan to the target registry. Default apply behavior MUST add `new` entries, skip `identical` entries, and fail without writing if any `conflict` entry exists. Applied imports MUST create missing topic files, update `index.md` routing rows, and preserve A-Z sorting within topic files.

#### Scenario: Apply imports new entry

- **WHEN** a valid bundle contains a new entry `docker/docker_logs` and a user runs `creg import commands.creg.md --apply`
- **THEN** the entry is added to `docker.md`, the routing table is updated if needed, and the command reports the added id

#### Scenario: Apply skips identical entry

- **WHEN** a valid bundle contains an entry identical to an existing target entry
- **THEN** `creg import commands.creg.md --apply` skips that entry and reports it as skipped

#### Scenario: Apply blocks on conflict by default

- **WHEN** a valid bundle contains a conflicting entry
- **THEN** `creg import commands.creg.md --apply` exits non-zero and does not write any imported entries

### Requirement: `creg import` supports explicit conflict modes

The `creg import <file> --apply` subcommand SHALL support explicit conflict modes: `--merge`, `--overwrite`, and `--rename-conflicts`. `--merge` MUST keep default apply behavior. `--overwrite` MUST replace conflicting target entries with bundle entries. `--rename-conflicts` MUST import conflicting bundle entries under deterministic new ids using an `_imported` suffix and MUST fail if the generated id already exists.

#### Scenario: Merge mode skips conflicts

- **WHEN** a bundle contains one new entry and one conflicting entry and a user runs `creg import commands.creg.md --apply --merge`
- **THEN** the new entry is added, the conflicting entry is skipped, and the command reports both outcomes

#### Scenario: Overwrite mode replaces conflict

- **WHEN** a bundle contains a conflicting entry and a user runs `creg import commands.creg.md --apply --overwrite`
- **THEN** the target entry with the same id is replaced by the bundle entry

#### Scenario: Rename conflicts imports with suffix

- **WHEN** a bundle contains conflicting `docker_logs` and no `docker_logs_imported` id exists
- **THEN** `creg import commands.creg.md --apply --rename-conflicts` imports the bundle entry as `docker_logs_imported`

#### Scenario: Rename conflict suffix collision fails

- **WHEN** a bundle contains conflicting `docker_logs` and `docker_logs_imported` already exists
- **THEN** `creg import commands.creg.md --apply --rename-conflicts` exits non-zero without modifying registry files
