# Token-Optimizing Agent Skills

A repository for custom token-optimizing skills designed for AI agents. This repo holds reusable, production-ready skills that reduce token overhead for common agent operations.

## Repository Structure

```
token-optimizing-agent-skills/
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

### code-review-fetch
Fetch GitHub PR review comments in a compact, token-efficient format. Extracts CodeRabbit's AI prompt blocks and synthesizes human inline comments into a uniform format, deduplicating across review rounds using local caching.

See `skills/code-review-fetch/README.md` for details.

### command-registry
A structured, per-project (and cross-project) registry of verified shell commands, parameterized templates, and explicit anti-patterns. Agents consult the registry before running commands to eliminate trial-and-error. Ships a CLI tool (`creg`) for writing and querying the registry, and a canonical activation snippet to inject into agent rules files.

See `skills/command-registry/README.md` for details.

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
