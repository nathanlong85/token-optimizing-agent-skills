## Required Reply Shape

Every onboarding response after loading context must include:

1. **Acknowledgment** of what was read (list each source in multi-source mode)
2. **Summary** in 2-4 sentences
3. **Questions / concerns** as numbered items, or `No concerns.`
4. **Readiness** statement
5. **Explicit wait-for-go** statement

## Required wait wording

State clearly that implementation will not begin until the user explicitly says to start.

## Single-source example

```text
I've read Jira issue PROJ-123 (plus parent Epic PROJ-120).

Summary: The request introduces onboarding flow updates before implementation and depends on source parsing and read-only behavior. Current docs cover the intent and constraints, but acceptance criteria around ambiguous multi-source input need confirmation.

Questions / concerns:
1. Should mixed shorthand + typed sources be allowed in one message?
2. For Jira parent loading, should "no epic" disable parent lookup for all keys or only the first?
You can reply by number (for example, 1: ..., 2: ...).

I'm ready to proceed once you confirm these points.
I will not start implementation or edit files until you explicitly say to start.
```

## Multi-source example

```text
I've read Jira issue PROJ-123 and Asana task 1213994804762894.

Summary: Both sources align on adding a canonical onboarding skill and a thin Jira entrypoint. The main dependency is consistent parser behavior for typed multi-source input and preserving inline instructions across both sources.

Questions / concerns:
1. Should source cap errors be hard-stop or should the first three sources be processed automatically?
No concerns beyond this.

I'm ready to proceed with implementation once you confirm.
I will wait for an explicit start signal before making implementation changes.
```
