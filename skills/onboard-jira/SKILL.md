---
name: onboard-jira
description: >
  Use when the user wants Jira-only onboarding with shorthand input such as
  /onboard-jira PROJ-123. Treats Jira as implicit source type, preserves
  trailing inline instructions, and follows the canonical onboarding read-only
  contract before implementation begins.
---

# /onboard-jira

Thin Jira entrypoint for the canonical onboarding workflow.

## Behavior

1. Parse first Jira input as implicit Jira source (`PROJ-123`, `PROJ-123,PROJ-456`, or Jira URL).
2. Preserve trailing text as inline instructions.
3. Normalize to canonical equivalent:
   - `/onboard jira:<jira-input> <inline instructions>`
4. Follow canonical onboarding behavior from `skills/onboard/SKILL.md`:
   - read-only onboarding
   - source loading + analysis
   - structured reply
   - explicit wait-for-go boundary

## Notes

- Do not duplicate full multi-source routing logic here.
- Do not start implementation until user explicitly says to start.
- This wrapper exists for ergonomic Jira onboarding while keeping shared behavior in `onboard`.
- Install requirement: `onboard-jira` depends on `onboard` being installed in same environment.
- If canonical `onboard` skill is unavailable, tell user to install both skills and stop.
