# Skill: ash-guardrails

**INVOKE BEFORE** editing Ash resources/actions/policies/notifiers.

## Use when
- Files under `*_ash/` or `lib/**/ash/**`.
- Adding actions, attributes, or policies.

## Checklist
- Keep resources thin: validations in changes, logic in actions, side-effects in notifiers.
- Authorization: define policies per action; default deny; use `bypass? false`.
- Queries: preload related data in queries to avoid N+1; use calculations instead of manual Enum maps.
- Changes: prefer `change set_attribute`/`change manage_relationship` over custom code.
- APIs: expose minimal public actions; avoid direct Repo access from controllers.

## Warnings to emit
- Direct Repo calls from controllers bypassing Ash APIs.
- Missing policy for custom actions.
- Large `after_action` blocks doing IO; move to notifiers/observers.

## References
- ai-rules patterns: `patterns/ash/` if present.
