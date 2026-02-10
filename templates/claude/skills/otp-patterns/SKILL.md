# Skill: otp-patterns

**INVOKE BEFORE** implementing or reviewing OTP components (Application, Supervisor, GenServer, Registry, DynamicSupervisor).

## Use when
- Adding or modifying supervised processes.
- Designing registries/dynamic supervisors.
- Debugging GenServer callbacks or timeouts.

## Checklist
- Separate client/API vs server callbacks.
- Add `@impl true` to callbacks; pattern match on messages.
- Avoid blocking in callbacks; offload to Tasks or async streams.
- Supervision: choose the lightest strategy (one_for_one default).
- Register via `Registry` or `{via, Registry, ...}` instead of global names.
- Instrument with telemetry events for critical paths.

## Quick snippets
- Start child: `Supervisor.start_child/2` for static; `DynamicSupervisor.start_child/2` for dynamic.
- Timeout hygiene: `handle_call` should avoid long work; use async reply when necessary.

## References
- ai-rules: `patterns/otp/` if present; follow BEAMAI defaults.
