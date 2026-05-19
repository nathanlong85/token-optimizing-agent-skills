# Agent Skills

A repository of custom skills for AI agents. Skills are built with token efficiency as a cross-cutting design principle, even when that's not their primary purpose.

## Repository Structure

```
agent-skills/
├── skills/
│   └── <skill-name>/
│       ├── README.md              # Skill documentation
│       ├── SKILL.md               # Skill manifest
│       ├── scripts/               # Implementation
│       └── ...
├── tests/
│   └── <skill-name>/              # Tests for that skill
│       ├── __init__.py
│       ├── test_*.py
│       └── ...
├── openspec/
│   ├── specs/                     # Main specification docs
│   └── changes/archive/           # Archived change documentation
└── CLAUDE.md                       # Project guidance for Claude Code
```

## Adding a New Skill

**Agents:** Before designing or changing any skill, read the official Agent Skills docs ([index](https://agentskills.io/llms.txt)): [specification](https://agentskills.io/specification.md), [best practices](https://agentskills.io/skill-creation/best-practices.md), [optimizing descriptions](https://agentskills.io/skill-creation/optimizing-descriptions.md), [evaluating skills](https://agentskills.io/skill-creation/evaluating-skills.md), [using scripts](https://agentskills.io/skill-creation/using-scripts.md). Then confirm to the user (with 🎉) that you have the full spec and creation docs before proceeding. Validate with `skills-ref validate ./skills/<skill-name>` when available.

1. **Create skill directory**:
   ```
   skills/<skill-name>/
   ```

2. **Create skill files**:
   - `SKILL.md` — Manifest describing the skill (name, description, commands, arguments, output)
   - `README.md` — User-facing documentation with setup, usage, and examples
   - `scripts/` — Implementation code

3. **Create tests**:
   ```
   tests/<skill-name>/
   ├── __init__.py
   ├── test_*.py
   └── ...
   ```
   Tests should import from the skill using relative paths:
   ```python
   sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../../skills/<skill-name>/scripts"))
   ```

4. **Optional: Document design decisions**:
   Use OpenSpec artifacts in `openspec/changes/` for design docs, proposals, and task tracking during development.

## Skills

### code-review-fetch `[token-use-reduction]`
Fetch GitHub PR review comments in a compact, token-efficient format. Extracts CodeRabbit's AI prompt blocks and synthesizes human inline comments into a uniform format, deduplicating across review rounds using local caching.

See `skills/code-review-fetch/README.md` for details.

### command-registry
A structured, per-project (and cross-project) registry of verified shell commands, parameterized templates, and explicit anti-patterns. Agents consult the registry before running commands to eliminate trial-and-error. Ships a CLI tool (`creg`) for writing and querying the registry, and a canonical activation snippet to inject into agent rules files.

See `skills/command-registry/README.md` for details.

### onboard
Onboard project/task context before implementation. Supports Jira, Asana, GitHub issue references, local files, URLs, and pasted descriptions with an explicit wait-for-go boundary.

- Canonical entrypoint: `/onboard`
- Thin Jira entrypoint: `/onboard-jira`
- Install note: install both `onboard` and `onboard-jira` for wrapper flow
- Multi-source mode supports typed prefixes such as `jira:`, `asana:`, `gh:`, `file:`, and `url:`

Install this repo's skills using your `skills` tool workflow, then invoke:

- `/onboard PROJ-123`
- `/onboard jira:PROJ-123 asana:1213994804762894`
- `/onboard-jira PROJ-123 Please run /opsx-new after onboarding`

See `skills/onboard/README.md` and `skills/onboard-jira/README.md` for details.

## Testing

Run tests for a specific skill:
```bash
pytest tests/<skill-name>/
```

Run all tests:
```bash
pytest tests/
```

## License

GPL-3.0 — See LICENSE file.
