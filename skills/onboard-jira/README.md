# onboard-jira

Thin Jira entrypoint for canonical onboarding workflow.

## Purpose

Allows short Jira-first invocation while reusing shared `onboard` behavior.

## Invocation

- `/onboard-jira PROJ-123`
- `/onboard-jira PROJ-123 Please skip parent epic`

## Dependency

Install `onboard` and `onboard-jira` together. Wrapper delegates to canonical `onboard` flow.
