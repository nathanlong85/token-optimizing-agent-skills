## Context

Agents working in a project re-discover the same shell-command shapes repeatedly across sessions — `gh api` paths and flags, project-specific Docker wrappers, Jenkins poll loops, JQL queries, etc. Each rediscovery is multiple failed attempts, each failure is a context-polluting tool result, and across sessions the knowledge doesn't accumulate. service-portal6 demonstrates the working pattern: a structured `.agents/rules/local/commands/` directory with verified commands, parameterized templates, and explicit anti-patterns, consulted before every shell command via a CLAUDE.local.md / `.mdc` rule. We want to package that pattern as a reusable skill in this repo.

## Goals / Non-Goals

**Goals:**
- Eliminate trial-and-error on commands that have a known good shape in the registry
- Make `anti_patterns` first-class — these prevent the most expensive retry loops
- Tool-agnostic data format (the registry is just markdown) so Claude, Cursor, Gemini, and others can all consume it
- A CLI that makes the write path mechanically consistent so agents don't drift the format
- Two scopes (project + global), with a clear classification rule so the agent knows where to write
- Installable manually without depending on any specific skill manager

**Non-Goals:**
- Auto-discovery of registry from arbitrary file paths — we standardize on `.agents/rules/local/command-registry/` (project) and `~/.agents/rules/command-registry/` (global)
- A networked / shared registry across teams — the global registry is per-user (users can point `CREG_GLOBAL_PATH` at a synced folder if they want, but we don't ship sync)
- Replacing or competing with general-purpose memory/note systems — the registry is specifically for verified shell-command syntax
- Enforcing the protocol via hooks — hooks are wrong-shaped for this (per-call overhead, no intelligent routing); the activation snippet in rules files is the right mechanism

## Decisions

### Directory layout and naming

```
skills/command-registry/
├── SKILL.md              ← protocol + when-to-consult + how-to-search rules
├── README.md             ← install instructions per scope, prerequisites
├── install.sh            ← optional helper: symlinks scripts/creg → ~/.local/bin/creg
├── scripts/
│   └── creg              ← executable bash script (no Python dependency)
└── template/
    └── index.md          ← starter index.md (routing table empty, rules + entry format populated)
```

**Rationale**: Mirrors `skills/code-review-fetch/` structure. `scripts/creg` (no extension) reads as a CLI on PATH. `template/index.md` is what `creg init` copies into a project. No default topic files — the registry starts empty and agents grow it organically.

**Alternative rejected**: bundling stock topic files (`git_github.md`, etc.). Rejected because projects vary too much in tooling; stock files would either be irrelevant or wrong for a given project.

### Registry directory locations

- **Project**: `.agents/rules/local/command-registry/` (relative to repo root; `creg` walks up from `$PWD` to find it, same strategy git uses)
- **Global**: `~/.agents/rules/command-registry/` by default; overridable via `CREG_GLOBAL_PATH` environment variable

**Rationale**: `.agents/rules/` is the tool-agnostic convention service-portal6 already uses and Cursor/Gemini may read natively. The `local/` subdirectory matches existing service-portal6 convention to signal "not committed by default." `CREG_GLOBAL_PATH` enables the synced-folder use case (Dropbox, iCloud) so the global registry follows users across machines.

**Alternative rejected**: putting the global registry under `~/.claude/` or `~/.cursor/`. Rejected because that ties it to a single tool; `~/.agents/` is tool-agnostic.

### Entry schema

```markdown
## snake_case_id            # globally unique across all topic files

intent: One line — what this command does.
tags: space or comma separated keywords
verified: Exact command that worked (omit if template alone suffices)
template: Parameterized form with {{placeholders}} (omit if verified alone suffices)
variants:
- Alternative form or flag
anti_patterns:
- Wrong form that tempts retries — explain why it fails
```

Sort `##` sections A–Z by id within each topic file.

**Rationale**: Schema lifted verbatim from service-portal6 — it's already battle-tested and the field set has converged. `anti_patterns` is the highest-leverage field for token savings.

### Project vs global classification

The agent classifies a new command by inspecting its content:

- **Contains a hardcoded project path, hostname, org/repo, or project-specific script** → project registry
- **Generic, uses `{{placeholders}}` for anything variable** → global registry

Examples:
```
Global:   gh api repos/{{owner}}/{{repo}}/pulls/{{pr}}/reviews
Project:  GH_HOST=github.groupondev.com gh api repos/prod-tools/service-portal/pulls/{{pr}}/reviews

Global:   rg -n "{{pattern}}" {{path}}
Project:  bin/dcdev rspec {{spec_path}}
```

**Rationale**: A simple binary rule the agent can apply without judgement calls. The classification is explicit in the activation snippet so the agent doesn't have to infer it.

### CLI surface

```bash
# Bootstrap
creg init [-g]                         # create registry directory + index.md from template

# Wiring (one-time setup per project)
creg inject <file...>                  # append activation snippet; detects .mdc → adds alwaysApply frontmatter; idempotent
creg link [--cursor]                   # create .cursor/rules/local/command-registry → .agents/rules/local/command-registry symlink

# Write (agent uses these)
creg add <topic> <id> \
  --intent "..." --tags "..." \
  [--verified "..."] [--template "..."] [--anti-pattern "..."] \
  [-g]                                 # -g writes to global registry

# Read (agents can also grep markdown directly)
creg search <keyword> [-g] [--all]
creg show <id>
creg list [-g] [--all]

# Maintenance
creg move <id> <topic> [-g]
creg validate [-g] [--all]
creg status                            # show registries, paths, entry counts
```

**Rationale**: `-g` mirrors `git config --global` — pattern users already know. `creg add` auto-creates topic files if they don't exist, so there's no separate `new-topic` subcommand (less surface area). `creg link` covers tools (like Cursor) that don't read `.agents/` natively. `creg status` is the diagnostic users reach for when something seems off.

**Implementation**: Shell script (bash + grep/sed/awk/mktemp). Zero runtime dependencies, works on macOS/Linux out of the box.

### Activation snippet (unified, scope-agnostic)

`creg inject` always writes the same snippet regardless of which registries are installed. "If present" guards handle any combination gracefully.

```
## Command Registry

Before running or suggesting any shell command — and before retrying after a failure —
check command registries (use whichever exist):

1. Project: .agents/rules/local/command-registry/ (if present)
2. Global: ~/.agents/rules/command-registry/ (or $CREG_GLOBAL_PATH if set)
Project wins on conflicts. For each registry found:
  a. Identify the right topic file from index.md routing table.
  b. Search (grep/rg) for the `## snake_case_id`, tags, or keyword. Read only that section.
  c. Prefer: exact verified → adapt template → closest intent.

After a command succeeds that isn't in the registry: use `creg add` to record it that turn.
  - Contains project-specific path/host/script → project registry (no -g)
  - Generic, works across repos → global registry (creg add ... -g)
  Print one line to the user: `Command registry: added <id>` or `Command registry: updated <id>`.

Extend existing entries. Avoid near-duplicates across topic files.
Registry wins for command shape. Project rules win for policy.
```

**Rationale**: One snippet, handles all install combinations, never needs updating when a new registry scope is added later. The "if present" guards mean an agent without a global registry simply skips that branch.

### Why not hooks

Hooks are designed for side effects (running shell commands as reactions to tool calls) and safety gates (blocking dangerous patterns). The registry is a reasoning protocol — Claude needs to internalize it and apply it selectively with judgement, not receive a mechanical reminder on every Bash call. A `PreToolUse` hook would fire on `ls`, `pwd`, `git status`, every trivial command, adding tool-result noise to the conversation. The activation snippet is read once at session start and applied with judgement — zero per-call overhead, intelligent application.

### CLI discovery (manual install fallback)

The agent finds `creg` in this order:
1. `creg` on PATH (covers global installs and any tool that handles PATH setup)
2. `<SKILL.md directory>/scripts/creg` (covers manual installs where PATH isn't configured)

This mirrors the `caveman-compress` discovery pattern. `install.sh` is offered as a convenience for users who want PATH setup without an external skill manager.

## Risks / Trade-offs

- [Risk] Agents may forget the "consult registry before commands" rule mid-session as context evolves → Mitigation: the activation snippet lives in always-read rules files (CLAUDE.md, `.mdc` with `alwaysApply: true`); we depend on the agent's compliance with persistent rules, same as any other rule-based protocol
- [Risk] Format drift if agents bypass `creg` and edit markdown directly → Mitigation: `creg validate` catches drift; the activation snippet directs writes through `creg add`
- [Risk] Cursor symlink approach requires manual `creg link` per project → Mitigation: documented in install instructions and `creg link` is one command; long-term, if Cursor adds native `.agents/` support, the symlink becomes unnecessary
- [Risk] Global registry pollution by project-specific commands when classification rule is misapplied → Mitigation: classification rule is simple (contains project-specific path? → project); `creg move <id> <topic> -g` allows relocation when misclassified
- [Trade-off] Shell-script CLI vs Python: shell wins on portability (no runtime dependency) but is harder to maintain for complex logic → Acceptable; the operations are fundamentally file I/O over markdown, well within shell's comfort zone
- [Trade-off] No default topic files: zero clutter for projects with unusual tooling, but new users see an empty registry → Acceptable; `index.md` ships with the schema and rules so the structure is immediately clear
