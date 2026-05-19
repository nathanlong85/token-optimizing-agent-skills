# command-registry

A structured, per-project (and cross-project) registry of verified shell commands, parameterized templates, and anti-patterns. Agents consult the registry before running commands, eliminating trial-and-error across sessions.

## Why

AI agents re-discover the same shell-command shapes repeatedly — `gh api` paths, Docker wrappers, CI poll loops, JQL queries. Each failed attempt pollutes context and wastes tokens. A registry of verified commands with explicit anti-patterns lets agents pick the right form on the first try and accumulate institutional knowledge that survives sessions.

## What ships

| File | Purpose |
|---|---|
| `SKILL.md` | Agent-facing protocol: when to consult, how to search, activation snippet |
| `scripts/creg` | CLI for writing and querying the registry |
| `template/index.md` | Starter `index.md` with rules and entry-format docs |
| `install.sh` | Optional helper to symlink `creg` into `~/.local/bin` |

## Install

### Option 1: `install.sh` (recommended)

```bash
bash skills/command-registry/install.sh
```

The installer now prompts before creating a global symlink at
`~/.local/bin/creg`.

Non-interactive options:

```bash
# install without prompts (and overwrite existing creg symlink/file)
bash skills/command-registry/install.sh --yes

# skip global install (use direct invocation only)
bash skills/command-registry/install.sh --skip-global-bin
```

If installed globally, ensure `~/.local/bin` is on your `PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Option 2: Manual symlink

```bash
ln -s "$(pwd)/skills/command-registry/scripts/creg" ~/.local/bin/creg
```

### Option 3: Direct invocation (no PATH setup needed)

```bash
./skills/command-registry/scripts/creg --version
```

Verify:

```bash
creg --version
```

## First-Use Flow

```bash
# 1. Bootstrap the project registry
creg init

# 2. Inject the activation snippet into your agent rules file
creg inject CLAUDE.md

# 3. (Cursor users only) Create symlink so Cursor discovers the registry
creg inject .cursor/rules/creg.mdc
creg link --cursor

# 4. Confirm everything looks right
creg status
```

## Registry Scopes

Two scopes exist; project takes precedence on conflicts.

| Scope | Default path |
|---|---|
| Project | `.agents/rules/local/command-registry/` (relative to repo root) |
| Global | `~/.agents/rules/command-registry/` |

`creg` walks up from `$PWD` to find the project registry (same strategy as `git`). Use `-g` / `--global` to target the global registry in any subcommand.

### Global registry override (`CREG_GLOBAL_PATH`)

To store the global registry in a synced folder (Dropbox, iCloud, etc.) that follows you across machines:

```bash
export CREG_GLOBAL_PATH="$HOME/Dropbox/command-registry"
creg init -g   # creates the registry under $CREG_GLOBAL_PATH
```

Add the export to your shell profile (`~/.zshrc`, `~/.bashrc`) so it persists.

## Project vs Global Classification

When recording a new command, classify by content:

| Contains | Registry |
|---|---|
| Hardcoded project path, hostname, org/repo, or wrapper script (`bin/dcdev`) | Project (no `-g`) |
| Generic — all variables use `{{placeholders}}` | Global (`-g`) |

**Examples:**

```bash
# Global — fully parameterized
creg add git_github pr_review_comments -g \
  --intent "List review comments on a PR" \
  --template "gh api repos/{{owner}}/{{repo}}/pulls/{{pr}}/comments"

# Project — hardcoded GH_HOST, org, repo
creg add git_github pr_review_comments_internal \
  --intent "List review comments on service-portal PRs" \
  --verified "GH_HOST=github.example.com gh api repos/prod-tools/service-portal/pulls/{{pr}}/comments"

# Global — generic grep
creg add shell rg_search -g \
  --intent "Search for a pattern recursively" \
  --template "rg -n \"{{pattern}}\" {{path}}"

# Project — project-specific Docker wrapper
creg add testing rspec_docker \
  --intent "Run RSpec inside Docker via project wrapper" \
  --template "bin/dcdev rspec {{spec_path}}"
```

## CLI Reference

```
creg init [-g]                       Bootstrap registry (copies template index.md)
creg inject <file...>                Add activation snippet to rules files
creg link --cursor                   Symlink project registry into .cursor/rules/local/

creg add <topic> <id> [flags] [-g]   Add entry
  --intent "..."    required
  --tags "..."
  --verified "..."  required if no --template
  --template "..."  required if no --verified
  --variant "..."   repeatable
  --anti-pattern "..."  repeatable

creg search <keyword> [-g] [--all]   Search entries
creg show <id> [-g] [--all]          Print one entry
creg list [-g] [--all]               List all entries

creg move <id> <new-topic> [-g]      Relocate entry between topic files
creg validate [-g] [--all]           Validate schema and routing-table consistency
creg status                          Show registry paths and entry counts
```

## Cursor and Gemini Notes

**Cursor**: Does not read `.agents/` natively. After `creg init`, run `creg link --cursor` to create a symlink at `.cursor/rules/local/command-registry`. Then inject the activation snippet into your `.mdc` rules file:

```bash
creg inject .cursor/rules/creg.mdc
```

The `.mdc` file gets `alwaysApply: true` frontmatter automatically.

**Gemini**: Registry consumption depends on which rules files Gemini reads in your project. Inject the snippet into whichever file Gemini picks up (`GEMINI.md`, `agents.md`, etc.) and verify that Gemini consults it during a session.

## Dependencies

- `bash` 4.0+
- Standard POSIX utilities: `grep`, `sed`, `awk`, `mktemp`

No Python, Node, or other runtimes required.
