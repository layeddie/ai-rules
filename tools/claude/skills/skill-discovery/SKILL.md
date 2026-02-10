# Skill: skill-discovery

**INVOKE BEFORE** working on Elixir/BEAM files. Determines which skills to load based on file patterns and task hints.

## Use when
- You open a file and are unsure which skill applies.
- The request spans multiple areas (OTP + LiveView + Ash).

## How it works
- Scan current file path/name and pick matching skills:
  - `lib/**/live/**/*.ex` or `lib/**/live_view/**/*.ex`: load `liveview-lifecycle`.
  - `lib/**/ash/**` or `*_ash/**`: load `ash-guardrails`.
  - `lib/**/ecto/**` or `priv/repo/migrations/*.exs`: load `ecto-query-analysis`.
  - `lib/**/otp/**` or modules ending with `Supervisor|Server|Worker`: load `otp-patterns`.
- If multiple match, list all; start with the most specific (Ash > LiveView > Ecto > OTP).

## Response pattern
- Summarize matched skills and why (1–2 bullets).
- Ask before loading heavy checklists if context is large.

## Notes
- Keep outputs concise; point to `tools/claude/README.md` for deeper docs when asked.
