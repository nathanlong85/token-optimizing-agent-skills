## Context

The existing personal `~/.cursor/skills/onboard` skill already defines a useful onboarding contract: parse context, load it, analyze ambiguity and risk, reply with a structured summary, and wait for explicit permission before implementation. This change makes that workflow installable from this repo and expands it to multiple source types while following the Agent Skills specification: valid hyphenated skill names, lean `SKILL.md`, progressive disclosure through `references/`, eval-driven iteration, and non-interactive scripts only when they add repeatable value.

The user decisions for this change are:

- Multi-source onboarding is supported with a cap, and typed prefixes are required when more than one source is supplied.
- Thin source-specific skills are included, starting with Jira.
- Compact Jira fetching is deferred until a separate `jira-fetch` skill exists.
- `disable-model-invocation: true` should be used so onboarding is explicit.

## Goals / Non-Goals

**Goals:**
- Add a canonical `skills/onboard/` skill that handles source routing, shared analysis, reply shape, and wait-for-go behavior.
- Add thin source-specific skills, beginning with `skills/onboard-jira/`, for ergonomic single-source invocation.
- Support multi-source onboarding through explicit prefixes such as `jira:`, `asana:`, `gh:`, `file:`, and `url:`.
- Preserve inline instructions as run-level guidance while keeping implementation blocked until the user explicitly starts.
- Include eval fixtures that cover activation, parsing, output shape, and read-only behavior.

**Non-Goals:**
- Do not implement a compact Jira or Asana data fetcher in this change.
- Do not make `command-registry` a hard dependency of `onboard`; agents should use it when installed and activated by repo rules.
- Do not support colon skill names such as `onboard:jira`, which are invalid under the Agent Skills spec.
- Do not make onboarding mutate Jira, GitHub, Asana, or local code during the onboarding step.

## Decisions

### Canonical workflow lives in `skills/onboard/`

The main `onboard` skill owns parsing, source routing, analysis, and the final response contract. Its `SKILL.md` should stay concise and load source-specific files only when a matching source is present.

Alternatives considered:
- Separate full skills for every source. Rejected because it would duplicate the wait-for-go and output contract.
- A single large `SKILL.md`. Rejected because it would load irrelevant source details on every run.

### Thin source-specific skills delegate to the canonical workflow

Add `onboard-jira` as a thin skill whose body says to use Jira as the implicit source type and follow the canonical onboarding workflow. This gives users the ergonomic `/onboard-jira PROJ-123` path while keeping shared behavior centralized.

Alternatives considered:
- Use `/onboard:jira`. Rejected because `name` values must be lowercase letters, numbers, and hyphens only, and must match the directory name.
- Only support `jira:` prefixes. Rejected because single-source Jira onboarding should remain short.

### Multi-source parsing requires explicit prefixes

For a single source, the canonical skill may infer type from a Jira key, supported URL, existing file path, or pasted text. For multiple sources, the skill requires type prefixes unless all sources are already unambiguous URLs.

This avoids guessing when values are opaque, especially for Asana task IDs and future source IDs.

### Inline instructions apply at run level

Trailing natural language that is not part of a parsed source is preserved as inline instructions. Those instructions can shape fetch scope and next-step behavior, but they cannot override the read-only onboarding boundary. For example, “Please immediately run `/opsx-new` after onboarding” is recorded and mentioned in readiness, but still requires the user’s explicit start/proceed signal before any further workflow executes.

### Fetchers are pluggable and deferred

Source references should prefer future compact fetch skills when available, but this change does not implement them. Until `jira-fetch` exists, Jira source instructions can describe how to use existing tools in a read-only way and rely on `command-registry` if the project has injected its activation snippet.

This keeps `onboard` as an orchestrator instead of turning it into a pile of API-specific extraction logic.

### Evals cover behavior rather than external service success

Initial evals should focus on prompts and expected agent behavior: routing, prefix requirements, reply structure, and no implementation before start. They should not require live Jira, Asana, or GitHub credentials. Live-source fetch quality can be evaluated later in the dedicated fetch skills.

## Risks / Trade-offs

- [Risk] Thin skills may drift from the canonical workflow. → Mitigation: make wrappers minimal and reference the canonical skill explicitly.
- [Risk] Multi-source parsing could misclassify manual instructions as sources. → Mitigation: require prefixes for multi-source, support an `instructions:` delimiter in examples, and ask when ambiguous.
- [Risk] Without compact fetchers, Jira or Asana output may be too verbose. → Mitigation: keep source references token-aware and defer richer trimming to dedicated fetch skills.
- [Risk] `disable-model-invocation: true` may prevent automatic activation when a user says “get up to speed.” → Mitigation: document explicit invocation and include thin commands/skills for common flows.

## Migration Plan

1. Add the repo version of the skill under `skills/onboard/`.
2. Add `skills/onboard-jira/` as the first thin wrapper.
3. Add eval fixtures and README references.
4. Validate with `skills-ref validate` when available.
5. Install via `skills` after implementation is accepted.
