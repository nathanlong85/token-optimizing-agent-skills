# creg-cli Specification

## Purpose

TBD - created as part of the `command-registry` change.

## Requirements

### Requirement: CLI executable and discovery

The skill SHALL ship a `creg` executable as a shell script at `skills/command-registry/scripts/creg`. The script MUST have no runtime dependencies beyond bash and standard POSIX utilities (`grep`, `sed`, `awk`, `mktemp`). Agents and users SHALL be able to invoke `creg` either as `creg` (when on `PATH`) or by an explicit path (e.g. `skills/command-registry/scripts/creg`).

#### Scenario: PATH invocation works after install.sh

- **WHEN** a user runs the optional `install.sh` and then types `creg --version` in a fresh shell
- **THEN** the command runs successfully without requiring Python, Node, or any other runtime

#### Scenario: Direct-path invocation works without PATH setup

- **WHEN** the skill has been cloned into a project but `install.sh` has not been run
- **THEN** running `./skills/command-registry/scripts/creg --version` from the repo root succeeds

### Requirement: `install.sh` offers optional global install

The optional `skills/command-registry/install.sh` helper SHALL support both interactive and non-interactive installation flows for exposing `creg` on `PATH`. By default, it MUST prompt whether to install a symlink at `~/.local/bin/creg`. The script MUST support `--yes` (`-y`) to install non-interactively and `--skip-global-bin` to skip global install while still succeeding and showing direct invocation guidance.

#### Scenario: Interactive default prompt

- **WHEN** a user runs `bash skills/command-registry/install.sh` in an interactive shell
- **THEN** the script prompts whether to install `~/.local/bin/creg` and follows the user's choice

#### Scenario: Non-interactive install with --yes

- **WHEN** a user runs `bash skills/command-registry/install.sh --yes`
- **THEN** the script installs `creg` to `~/.local/bin/creg` without prompting and overwrites an existing target if needed

#### Scenario: Skip global install

- **WHEN** a user runs `bash skills/command-registry/install.sh --skip-global-bin`
- **THEN** the script exits successfully without creating `~/.local/bin/creg` and prints direct-path usage for `scripts/creg`

### Requirement: Global flag

Every subcommand that targets a specific registry scope SHALL accept a `-g` (long form: `--global`) flag. When `-g` is absent the subcommand operates on the project registry. When `-g` is present the subcommand operates on the global registry. Subcommands that operate on both registries simultaneously SHALL accept `--all` instead.

#### Scenario: Default scope is project

- **WHEN** an agent runs `creg add git_github pr_view --intent "..." --verified "..."`
- **THEN** the entry is written to `.agents/rules/local/command-registry/git_github.md`

#### Scenario: Global scope via -g

- **WHEN** an agent runs `creg add git_github pr_view --intent "..." --verified "..." -g`
- **THEN** the entry is written to the global registry at `~/.agents/rules/command-registry/git_github.md` (or `$CREG_GLOBAL_PATH/git_github.md` if set)

### Requirement: `creg init` bootstraps a registry

The `creg init` subcommand SHALL create the target registry directory and copy a template `index.md` into it. With no flag the project registry is created; with `-g` the global registry is created. Running `creg init` against an already-initialized registry MUST be a no-op and exit successfully with an informative message.

#### Scenario: Init creates project registry

- **WHEN** `creg init` is run in a repo without an existing project registry
- **THEN** `.agents/rules/local/command-registry/index.md` is created from the skill's template

#### Scenario: Init is idempotent

- **WHEN** `creg init` is run a second time in a repo that already has a project registry
- **THEN** the command exits with status 0 and prints a message indicating no changes were made

### Requirement: `creg inject` adds activation snippet to rules files

The `creg inject <file>...` subcommand SHALL append the canonical activation snippet to each specified file. When the file extension is `.mdc`, `creg inject` MUST prepend or merge a YAML frontmatter block containing `alwaysApply: true`. The operation SHALL be idempotent -- running `creg inject` against a file that already contains the activation snippet MUST be a no-op.

#### Scenario: Inject into CLAUDE.md

- **WHEN** a user runs `creg inject CLAUDE.md` against a fresh CLAUDE.md file
- **THEN** the activation snippet is appended as plain markdown after a blank line

#### Scenario: Inject into Cursor .mdc file

- **WHEN** a user runs `creg inject .cursor/rules/creg.mdc` and the file does not yet exist
- **THEN** the file is created with YAML frontmatter containing `alwaysApply: true` followed by the activation snippet

#### Scenario: Idempotent re-injection

- **WHEN** a user runs `creg inject CLAUDE.md` twice in a row
- **THEN** the second invocation detects the existing snippet, prints a notice, and does not modify the file

#### Scenario: Multiple files in one invocation

- **WHEN** a user runs `creg inject CLAUDE.md .cursor/rules/creg.mdc GEMINI.md`
- **THEN** each file is processed independently with the appropriate format and idempotency check

### Requirement: `creg link` creates symlinks for tools that don't read .agents/

The `creg link --cursor` subcommand SHALL create a symlink from `.cursor/rules/local/command-registry` pointing at `.agents/rules/local/command-registry`. The operation MUST be idempotent and MUST detect a pre-existing correct symlink as a no-op.

#### Scenario: Cursor symlink created

- **WHEN** a user runs `creg link --cursor` in a project that has a project registry but no `.cursor/rules/local/command-registry` symlink
- **THEN** the symlink is created and Cursor can now discover the registry through its native `.cursor/rules/` rule-loading path

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

### Requirement: `creg move` relocates entries between topic files

The `creg move <id> <new-topic>` subcommand SHALL move an entry from its current topic file to the specified destination topic file within the same registry, creating the destination file and updating the routing table if necessary. If after the move the source topic file contains no entries, the source file MUST be deleted and its routing-table row removed.

#### Scenario: Move from other.md into a new dedicated topic

- **WHEN** `other.md` contains five docker-related entries and a user runs `creg move docker_compose_up docker` (where `docker.md` does not yet exist)
- **THEN** `docker.md` is created with the entry, `other.md` is updated to remove the entry, and the routing table is updated to add a `docker.md` row

#### Scenario: Source file removed when emptied

- **WHEN** `creg move` removes the last entry from `lint.md`
- **THEN** `lint.md` is deleted and its row is removed from `index.md`'s routing table

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

### Requirement: `creg status` shows registry configuration

The `creg status` subcommand SHALL print, for both registries, whether they exist, their resolved paths, and the number of entries they contain. The output MUST also indicate when `CREG_GLOBAL_PATH` is overriding the default global location.

#### Scenario: Both registries present

- **WHEN** a user runs `creg status` with both a project and global registry present
- **THEN** the output lists both registries with their paths and entry counts on separate lines

#### Scenario: Only project registry exists

- **WHEN** the project registry exists but no global registry has been initialized
- **THEN** `creg status` prints the project registry's path and entry count and indicates the global registry is not present

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
