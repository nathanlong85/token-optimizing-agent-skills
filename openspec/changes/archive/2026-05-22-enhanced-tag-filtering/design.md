## Context

The command-registry skill stores command entries in markdown topic files. Tags already exist, but `creg add` writes them as a single free-form line (`tags: openspec status change`) and `creg search` matches them with substring grep. That keeps the format simple, but it makes precise filtering impossible and can produce false positives such as matching `prod` inside `nonprod`.

The repo's core constraint is token efficiency: agents should find the smallest relevant registry section without broad reads or extra probing commands. The implementation also needs to stay compatible with the existing bash-only `creg` script and its current dependency contract.

## Goals / Non-Goals

**Goals:**

- Define a canonical list format for tags that is easy for humans to read and easy for bash to parse.
- Keep existing inline tag entries searchable and valid during a transition period.
- Add precise tag filters to `creg search` without changing the default keyword-search behavior.
- Provide tag maintenance commands that help users normalize registries without loading whole files into an agent context.
- Update agent guidance so agents use structured tag search when tag precision matters.

**Non-Goals:**

- Replace markdown topic files with a database or generated index.
- Add runtime tool-prerequisite checks before every command.
- Introduce dependencies such as Python, Node, `jq`, `yq`, or a YAML parser.
- Automatically rewrite user registries unless the user explicitly runs the migration command.

## Decisions

### Canonical tags use a markdown/YAML-style list

New entries should be written as:

```markdown
tags:
  - openspec
  - status
  - change
```

This mirrors existing `variants:` and `anti_patterns:` list fields, keeps diffs readable, and avoids inventing a separate delimiter grammar. Alternatives considered were comma-separated inline strings and bracket arrays (`tags: [openspec, status]`). Comma-separated strings are the current source of ambiguity, and bracket arrays add parsing edge cases without improving agent readability.

### Legacy inline tags remain readable

The parser should accept both `tags: openspec status change` and the canonical list form. `creg add` and `creg upgrade-tags` should write only the canonical list form. This avoids a breaking change while still letting the registry converge on one format.

Legacy parsing should split inline tags on commas and whitespace, trim empty values, and normalize to the same in-memory representation as list-form tags. Quoted multi-word tags should not be supported; tag names should be small lookup tokens, not prose.

### Tag filters live on `creg search`

`creg search` should keep its existing keyword form:

```bash
creg search "openspec" --all
```

Structured tag filtering should be additive:

```bash
creg search --tags openspec,status
creg search --any-tags openspec,status
creg search --tags openspec --exclude-tags deprecated
creg search --tags openspec "status"
```

Default semantics for `--tags` should be AND because it narrows results and best supports token-efficient lookup. `--any-tags` provides OR semantics when discovery is broader. `--exclude-tags` removes entries containing any excluded tag. If a keyword is also supplied, the result must satisfy both the tag filter and the keyword filter.

### Tag inventory is a separate read command

Add `creg tags` for maintenance:

```bash
creg tags
creg tags --counts
creg tags --untagged
creg tags --all
creg tags -g
```

Keeping inventory separate from search keeps `creg search` focused on finding command entries. `creg tags --counts` gives users a compact view of tag vocabulary and helps catch near-duplicates by inspection.

### Validation enforces small, predictable tag tokens

`creg validate` should reject duplicate tags within one entry and tag names that are not lowercase alphanumeric with hyphens (`^[a-z0-9][a-z0-9-]*$`). This matches the registry's bias toward grep-friendly identifiers. The validator should accept legacy inline syntax but can warn when legacy syntax is present, nudging users toward `creg upgrade-tags`.

### Migration is explicit and idempotent

Add `creg upgrade-tags [-g|--all] [--dry-run]` to rewrite legacy inline tags into canonical lists. `--dry-run` should report affected entry IDs and files without modifying files. Re-running the command after migration should be a no-op.

### Activation snippet mentions structured tag search

The canonical activation snippet should continue to allow grep/ripgrep for ID or keyword lookup, but should explicitly direct agents to `creg search --tags` when the lookup is tag-based. This prevents agents from using raw substring grep when AND/OR/exclude semantics matter.

## Risks / Trade-offs

- Existing user-authored inline tags may contain prose or punctuation -> Mitigation: legacy readers accept the old format for search, while validation reports actionable tag-format errors and migration is opt-in.
- Bash parsing can become brittle -> Mitigation: keep supported tag syntax intentionally narrow and add focused shell tests for inline tags, list tags, AND/OR/exclude matching, and migration.
- Multi-line parsing makes search slower than a single grep -> Mitigation: registries are small markdown files, and precise filtering reduces downstream token usage by avoiding irrelevant sections.
- Activation snippets already injected into user rules will not update automatically -> Mitigation: document that users can re-run `creg inject` or manually update the snippet; keep old guidance functional.
