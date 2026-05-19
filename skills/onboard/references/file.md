## Local File Source Loading

Use for `file:<path>` or path-like single-source inputs.

## Accepted forms

- `file:doc/handover.md`
- `file:/absolute/path/to/plan.txt`
- `doc/handover.md` (single-source mode when path exists)

## Loading behavior

1. Resolve relative paths from workspace root.
2. Read text/markdown directly.
3. For large files, read the full file only when reasonable; otherwise summarize key sections.
4. For PDFs, extract readable text and summarize; avoid dumping the entire document into context.

## Failure handling

- If file is missing or unreadable, ask for a corrected path or pasted content.
- In multi-source mode, continue with other sources.
