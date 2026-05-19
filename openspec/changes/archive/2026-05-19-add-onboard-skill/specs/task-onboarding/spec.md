## ADDED Requirements

### Requirement: Explicit onboarding activation
The onboarding skill SHALL activate for explicit onboarding intent and SHALL remain read-only until the user explicitly starts implementation.

#### Scenario: User invokes canonical onboarding
- **WHEN** the user invokes `/onboard` with a supported source or asks to onboard before starting work
- **THEN** the skill loads task context, summarizes it, surfaces questions or concerns, states readiness, and states that it will not implement or edit files until the user explicitly says to start

#### Scenario: User has not started implementation
- **WHEN** the onboarding reply has been sent and the user has not said to start, proceed, begin, go, or equivalent
- **THEN** the agent does not edit files, run code-changing tools, transition tickets, or otherwise begin implementation

### Requirement: Source parsing and routing
The onboarding skill SHALL parse one or more task context sources and route each source to the matching source reference.

#### Scenario: Single Jira shorthand
- **WHEN** the user invokes `/onboard PROJ-123`
- **THEN** the skill treats `PROJ-123` as a Jira source and loads the Jira source instructions

#### Scenario: Multi-source typed prefixes
- **WHEN** the user invokes `/onboard jira:PROJ-123 asana:1213994804762894`
- **THEN** the skill treats the request as a multi-source onboarding run, loads both Jira and Asana source instructions, and keeps each loaded source labeled in the combined context

#### Scenario: Multi-source without unambiguous types
- **WHEN** the user supplies more than one bare source token and the source types cannot be inferred unambiguously
- **THEN** the skill asks the user to add type prefixes such as `jira:`, `asana:`, `gh:`, `file:`, or `url:` before fetching context

#### Scenario: URL routing
- **WHEN** the user supplies a supported URL to Jira, Asana, GitHub issue, or a generic webpage
- **THEN** the skill routes the URL based on host and path where possible, otherwise routes it through the generic URL source instructions

### Requirement: Multi-source limits and inline instructions
The onboarding skill SHALL support a bounded number of sources and SHALL preserve trailing user instructions as run-level guidance.

#### Scenario: Multi-source cap
- **WHEN** the user supplies more sources than the configured cap
- **THEN** the skill asks the user to reduce the source list before fetching context

#### Scenario: Trailing manual instructions
- **WHEN** the user invokes `/onboard-jira PROJ-123 Please immediately run /opsx-new after onboarding`
- **THEN** the skill treats `PROJ-123` as the Jira source and records the trailing sentence as inline instructions to follow after the onboarding summary, subject to the explicit wait-for-go boundary

### Requirement: Thin source-specific onboarding skills
The repository SHALL provide thin source-specific onboarding skills that delegate to the canonical onboarding workflow while allowing ergonomic single-source invocation.

#### Scenario: Jira-specific entrypoint
- **WHEN** the user invokes `/onboard-jira PROJ-123`
- **THEN** the source-specific skill uses Jira as the implicit source type, applies the canonical onboarding workflow, and does not require the user to write `jira:PROJ-123`

#### Scenario: Shared workflow consistency
- **WHEN** a thin source-specific onboarding skill produces an onboarding response
- **THEN** the response follows the same summary, questions or concerns, readiness, and explicit wait structure as the canonical `onboard` skill

### Requirement: Progressive disclosure for source behavior
The onboarding skill SHALL keep the main `SKILL.md` concise and load source-specific details from `references/` only when needed.

#### Scenario: Jira source reference
- **WHEN** a parsed source is Jira
- **THEN** the skill loads Jira-specific instructions from a Jira reference file and applies parent Epic defaults unless inline instructions forbid them

#### Scenario: Asana source reference
- **WHEN** a parsed source is Asana
- **THEN** the skill loads Asana-specific instructions from an Asana reference file and uses the configured source access path, falling back to asking the user to paste content when authenticated access is unavailable

### Requirement: Evals for onboarding behavior
The onboarding skill SHALL include eval cases covering trigger behavior, source parsing, output shape, and read-only boundaries.

#### Scenario: Eval fixture exists
- **WHEN** the onboarding skill is added
- **THEN** `skills/onboard/evals/evals.json` contains realistic prompts for single-source, multi-source, source-specific entrypoint, trailing instructions, and near-miss negative cases
