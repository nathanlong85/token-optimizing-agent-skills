# Command Registry

## Route

| Task | Topic file |
|---|---|

## Rules

**Consult this registry before running or suggesting any shell command**, and before retrying after a failure.

**How to search:**

1. Identify the right topic file from the Route table above.
2. Search (grep/rg) for `## snake_case_id` or a keyword. Read only that section.
   For precise tag filtering: `creg search --tags tag1[,tag2]`.
3. Prefer: exact `verified` → adapt `template` → closest `intent`.
4. If retrying after a failure, re-scan `anti_patterns` in the matched entry before changing command shape.

**Same-turn updates:** After a command succeeds that isn't in the registry, record it immediately with `creg add`. Print one line: `Command registry: added <id>` or `Command registry: updated <id>`.

**Dedup:** Extend existing entries with new `variants` or `anti_patterns`. Don't create near-duplicates across topic files.

**Conflict resolution:** Registry wins for command shape. Project rules win for policy. Example: if verified shape is `rspec spec/foo_spec.rb` but policy says "always use Docker", apply Docker on top of the verified shape: `bin/dcdev rspec spec/foo_spec.rb`.

**Classification rule for new commands:**

- Contains project-specific path, hostname, org/repo, or wrapper script → project registry (no `-g`)
- Generic, parameterized with `{{placeholders}}` → global registry (`creg add ... -g`)

## Entry Format

Each entry in a topic file is a level-2 heading (`## snake_case_id`) followed by fields:

```
## snake_case_id

intent: One line — what this command does.
tags:
- keyword-one
- keyword-two
verified: Exact command that worked (omit if template alone suffices)
template: Parameterized form with {{placeholders}} (omit if verified alone suffices)
variants:
- Alternative form or flag combination
anti_patterns:
- Wrong form that tempts retries — explain why it fails
```

**Field rules:**

- `intent` — required; one line
- `tags` — optional; canonical list form (`tags:` followed by `- tag` bullets). Legacy inline strings remain readable.
- `verified` — at least one of `verified` or `template` must be present
- `template` — at least one of `verified` or `template` must be present
- `variants` — optional; bulleted list
- `anti_patterns` — optional; bulleted list; highest-leverage field for saving tokens

Entries within each topic file are sorted A–Z by `id`.
