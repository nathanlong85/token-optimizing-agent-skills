---
name: command-registry
description: >
  Use this skill when an agent needs to run, suggest, or retry shell commands.
  Provides a searchable project/global registry of verified command shapes,
  templates, and anti-patterns so agents avoid trial-and-error and reuse known-good
  patterns.
compatibility: Requires bash 4.0+ and standard POSIX utilities (grep, sed, awk, mktemp).
metadata:
  env_var_creg_global_path: "Override default global registry path (~/.agents/rules/command-registry)"
---

# Command Registry

## Purpose

The command-registry skill ships:

1. **A data format** — markdown topic files with structured `## snake_case_id` entries containing `intent`, `tags`, `verified`, `template`, `variants`, and `anti_patterns` fields.
2. **A CLI tool (`creg`)** — writes and queries the registry with schema validation, dedup, A–Z insertion, and routing-table maintenance.
3. **A canonical activation snippet** — injected into agent rules files so agents consult the registry automatically before running commands.

Two registry scopes are supported:

- **Project**: `.agents/rules/local/command-registry/` (relative to repo root; not committed by default)
- **Global**: `~/.agents/rules/command-registry/` (or `$CREG_GLOBAL_PATH` if set)

Project entries take precedence on conflicts.

## Prerequisites

- `bash` (4.0 or later)
- Standard POSIX utilities: `grep`, `sed`, `awk`, `mktemp`

Verify installation:

```bash
creg --version
```

## CLI Discovery

The agent locates `creg` in this order:

1. `creg` on `PATH` (covers global installs via `install.sh` or a package manager)
2. `<SKILL.md directory>/scripts/creg` (covers manual installs where `PATH` is not configured)

To use the fallback without `PATH` setup:

```bash
./skills/command-registry/scripts/creg --version
```

## Activation Snippet

`creg inject <file>` appends the following snippet verbatim. Agents that read the file will apply the protocol automatically.

```markdown
## Command Registry

Before running or suggesting any shell command — and before retrying after a failure —
check command registries (use whichever exist):

1. Project: .agents/rules/local/command-registry/ (if present)
2. Global: ~/.agents/rules/command-registry/ (or $CREG_GLOBAL_PATH if set)
Project wins on conflicts. For each registry found:
  a. Identify the right topic file from index.md routing table.
  b. Search (grep/rg) for the `## snake_case_id`, tags, or keyword. Read only that section.
  c. Prefer: exact verified → adapt template → closest intent.
  d. If retrying after a failure, re-scan `anti_patterns` in the matched entry before changing command shape.

After a command succeeds that is not in the registry: use `creg add` to record it that turn.
  - Contains project-specific path/host/script → project registry (no -g)
  - Generic, works across repos → global registry (creg add ... -g)
  Print one line to the user: `Command registry: added <id>` or `Command registry: updated <id>`.

Extend existing entries. Avoid near-duplicates across topic files.
Registry wins for command shape. Project rules win for policy.
```

## Project vs Global Classification

When recording a new command, classify it by inspecting its content:

| Command contains | Registry |
| --- | --- |
| Hardcoded project path, hostname, org/repo, or project-specific script (`bin/dcdev`) | Project (no `-g`) |
| Generic form — all variables use `{{placeholders}}` | Global (`-g`) |

Examples:

```bash
# Global — no hardcoded values
gh api repos/{{owner}}/{{repo}}/pulls/{{pr}}/reviews

# Project — hardcoded GH_HOST, org, and repo
GH_HOST=github.example.com gh api repos/prod-tools/service-portal/pulls/{{pr}}/reviews

# Global
rg -n "{{pattern}}" {{path}}

# Project — project-specific wrapper script
bin/dcdev rspec {{spec_path}}
```

## Typical First-Use Flow

```bash
# 1. Bootstrap the project registry
creg init

# 2. Inject the activation snippet into your agent rules file
creg inject CLAUDE.md
# For Cursor:
creg inject .cursor/rules/creg.mdc

# 3. (Cursor only) Create symlink so Cursor discovers the registry
creg link --cursor

# 4. Verify
creg status
```
