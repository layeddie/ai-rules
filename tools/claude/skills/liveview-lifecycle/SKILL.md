# Skill: liveview-lifecycle

**INVOKE BEFORE** creating or changing LiveView modules, components, or uploads.

## Use when
- Working in `lib/*_web/live/` or `lib/*_web/components/`.
- Handling events, params, or uploads.

## Checklist
- Mount: guard for connected?; load minimal assigns; defer heavy loads to `handle_params`.
- Handle params: use pattern matching on params; push_patch for navigation.
- Events: validate input; throttle noisy events; use PubSub for cross-process updates.
- Assigns: always use `assign/3` or `stream_insert`; avoid direct map updates.
- Uploads: configure `allow_upload` with size limits; use `consume_uploaded_entries`.
- Navigation: prefer `push_navigate` for live redirects; `redirect` only when leaving LV.

## Gotchas
- Avoid Repo calls in render/handle_info without rate-limiting.
- Ensure components use `attr :id, :string` where needed.
- Include `static_paths/0` entries for assets referenced in hooks.
