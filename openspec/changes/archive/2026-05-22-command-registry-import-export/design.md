## Context

The command-registry source of truth is markdown topic files plus an `index.md` routing table. That format is friendly for agents and humans, but users still need a way to share or back up a curated set of entries without copying an entire registry directory or manually splitting topic files.

The `creg` script currently promises bash plus standard POSIX utilities only. Import support is riskier than export because it writes registry files, so the format must be easy to parse safely without `jq`, `yq`, Python, or Node.

## Goals / Non-Goals

**Goals:**

- Add a portable import/export workflow for complete registries or filtered entry sets.
- Preserve markdown topic files as the normal storage format.
- Keep import behavior safe by default with dry-run preview and explicit conflict decisions.
- Reuse existing registry validation, sorted insertion, and routing-table updates.
- Keep output compact enough for agents to inspect without dumping full registries unnecessarily.

**Non-Goals:**

- Replace registry storage with JSON, YAML, SQLite, or another database.
- Add external parser dependencies.
- Implement full YAML or JSON import in the first version.
- Sync registries continuously or manage remote sharing.
- Resolve semantic differences between conflicting entries automatically.

## Decisions

### Use a native markdown bundle format for roundtrip import/export

The first importable format should be a deterministic markdown bundle:

```markdown
# Command Registry Export
format: creg-bundle-v1
source_scope: project

## docker/docker_logs

intent: Stream logs from a running container
tags:
  - docker
  - logs
template: docker logs -f {{container}}
```

Each exported entry uses `## <topic>/<id>` so import can reconstruct the topic file without a separate JSON/YAML parser. The entry body reuses the existing registry field syntax. This keeps the transport readable, diffable, and close to the canonical registry format.

Alternatives considered:

- YAML: pleasant for humans, but robust import would require a parser dependency.
- JSON/JSONL: good for machines, but shell-safe escaping and multi-line list parsing are brittle without `jq`.
- Tar/zip directory archives: preserve files exactly, but make selective import and conflict reporting harder for agents to inspect.

### Export can be filtered, but defaults should be conservative

`creg export` should default to writing the target registry as a bundle on stdout. Flags can narrow the export:

```bash
creg export
creg export -g
creg export --all
creg export --topic docker
creg export --id docker_logs
creg export --tags docker,logs
creg export --verified-only
creg export --output commands.creg.md
```

Filtering should happen before output so agents avoid producing large bundles when only a small set of commands is needed.

### Import defaults to preview, not mutation

`creg import <file>` should run in dry-run mode by default and print a compact plan. Users or agents must pass an explicit apply flag to write:

```bash
creg import commands.creg.md
creg import commands.creg.md --apply
```

This is safer for shared command bundles, where overwriting a local verified command could degrade future shell behavior.

### Conflict handling is explicit

During import, each bundle entry should be classified:

- `new`: no entry with that id exists in the target registry.
- `identical`: an entry with that id exists and its normalized body matches.
- `conflict`: an entry with that id exists but differs.

Default apply behavior should add `new`, skip `identical`, and fail without writing if any `conflict` exists. Explicit conflict modes:

```bash
creg import commands.creg.md --apply --merge
creg import commands.creg.md --apply --overwrite
creg import commands.creg.md --apply --rename-conflicts
```

`--merge` is the safe default behavior and may be accepted explicitly for clarity. `--overwrite` replaces conflicting local entries. `--rename-conflicts` imports conflicting entries under a deterministic suffix such as `<id>_imported`, failing if that generated id also exists.

### Import writes atomically enough for local markdown files

Import should parse and validate the whole bundle first. If validation fails, no registry files are modified. For apply mode, write affected topic files through temp files and only move them into place after all planned changes for a file are prepared. This keeps partial writes unlikely and makes failures easier to reason about.

### Optional machine-readable summaries can be added without changing the bundle

The primary import/export payload should stay markdown. If agents need structured summaries, `creg import --json-summary` or `creg export --json-summary` can later emit compact metadata only. That avoids making JSON the interchange format before the project has a parser dependency.

## Risks / Trade-offs

- Users may expect YAML/JSON because "import/export" often implies those formats -> Mitigation: document that `creg-bundle-v1` is the dependency-free roundtrip format, with JSON/YAML deferred until parser support exists.
- Markdown bundle parsing can still be fragile -> Mitigation: keep the grammar narrow, require `## topic/id` headings, and validate the full bundle before writes.
- Dry-run default may surprise users expecting immediate import -> Mitigation: the preview output should include the exact `--apply` command to execute the plan.
- Overwrite mode can remove local project-specific improvements -> Mitigation: require explicit `--overwrite`, report every overwritten id, and preserve project/global scope selection rules.
