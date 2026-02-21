# Nix Strategy Refresh Implementation Plan (Local Elixir Projects)

**Date**: 2026-02-21  
**Based On**: `/Users/elay14/projects/2026/ai-rules/spec_for_nix.md`  
**Scope**: Local-first Nix strategy for ai-rules Elixir projects (Elixir, Phoenix/Ash/LiveView, Nerves, Gleam, Rustler)

---

## 1. Goal

Define and implement a modern, reproducible Nix strategy for local Elixir development that:

- Keeps flakes as the default dev environment mechanism.
- Works cleanly with Determinate Nix + direnv on macOS.
- Adds explicit guidance for OrbStack-based NixOS/container workflows.
- Produces AI-consumable guidance in `tools/nixos/`.
- Replaces legacy init flow with an LLM-agnostic v2 flow while preserving old files.

---

## 2. Key Outcomes (What Will Exist)

1. New Nix knowledge base under `tools/nixos/`:
- `tools/nixos/README.md`
- `tools/nixos/nix.md`
- `tools/nixos/nixos.md`
- `tools/nixos/elixir_flakes.md`

2. Updated project bootstrap artifacts (without deleting legacy files):
- `scripts/init_project_v2.sh` (new)
- `PROJECT_INIT_V2.md` (new)

3. Curated flake examples and patterns:
- Elixir library
- Phoenix + Ash + LiveView
- Nerves
- Gleam
- Elixir + Rust (Rustler)
- Universal mixed stack

4. Validation matrix and runbook alignment:
- Local `nix develop` flow
- direnv flow
- containerized dev shell flow
- basic CI compatibility checks

---

## 3. Current-State Findings (From Repo Review)

1. Good baseline exists:
- `configs/nix_flake_universal.nix`
- `configs/nix_flake_phoenix_ash.nix`
- `configs/nix_flake_nerves.nix`
- `docs/nix_flake_runbook.md`

2. `tools/nixos/` exists but is currently empty.

3. `scripts/init_project.sh` and `PROJECT_INIT.md` are tied to older workflow assumptions and should remain as legacy references.

4. Existing initialization docs should be superseded by a neutral, tool-agnostic flow that still supports symlinked `ai-rules` setup.

5. `docs/plans/` is currently ignored by `.gitignore`, so plan artifacts are not version-tracked unless ignore rules are adjusted.

---

## 4. Implementation Strategy

## Phase 1: Foundation and Information Architecture

**Objective**: Create the `tools/nixos` documentation structure and define the canonical strategy.

**Tasks**:
1. Create `tools/nixos/README.md` as entrypoint and decision map.
2. Create `tools/nixos/nix.md` for local devshell standards (flakes, overlays, pinning, direnv).
3. Create `tools/nixos/nixos.md` for NixOS VM/container guidance and host constraints.
4. Create first version of `tools/nixos/elixir_flakes.md` with curated examples and copy-ready snippets.

**Deliverable**:
- Complete and navigable `tools/nixos/` knowledge tree.

**Commit**:
- `docs: add nixos knowledge base for local elixir development`

---

## Phase 2: Canonical Flake Patterns and Version Policy

**Objective**: Standardize flake patterns used by ai-rules templates.

**Tasks**:
1. Define shared flake conventions:
- pinned `nixpkgs` channel policy
- default BEAM versioning policy
- Darwin/Linux conditional dependencies
- deterministic shell env vars (`MIX_HOME`, `HEX_HOME`, etc.)

2. Define a canonical template matrix (minimal, web, embedded, typed, native-ext).

3. Map each template to required tools and optional tools.

**Deliverable**:
- Flake pattern matrix documented in `tools/nixos/elixir_flakes.md`.

**Commit**:
- `docs: define canonical flake patterns for ai-rules elixir projects`

---

## Phase 3: Local Container and NixOS Strategy

**Objective**: Document and validate containerized dev shell options.

**Tasks**:
1. Add "when to use" guidance:
- native host `nix develop`
- containerized dev shell
- NixOS VM workflow (OrbStack-friendly)

2. Document constraints:
- NixOS containers are Linux-oriented; macOS should use VM/container runtime.

3. Provide sample developer flows:
- start shell locally
- start shell in container
- run `mix deps.get`, `mix test`, `mix phx.server` in both modes

**Deliverable**:
- `tools/nixos/nixos.md` with practical flows and caveats.

**Commit**:
- `docs: add nixos and containerized dev shell guidance`

---

## Phase 4: Bootstrap Modernization (LLM-Agnostic)

**Objective**: Create v2 initialization flow aligned with current strategy.

**Tasks**:
1. Create `scripts/init_project_v2.sh` that follows the spec sequence:
- choose project language and versions
- choose nix template
- create nix shell and ai-rules symlink
- run mix/new-project bootstrap inside nix shell

2. Keep provider/tool neutrality:
- no hard dependency on one coding assistant tool
- optional integration hooks documented, not coupled

3. Create `PROJECT_INIT_V2.md` with end-to-end bootstrap examples.

4. Keep existing `scripts/init_project.sh` and `PROJECT_INIT.md` untouched as legacy.

**Deliverable**:
- New v2 bootstrap path and docs.

**Commit**:
- `feat: add llm-agnostic nix-first project bootstrap v2`

---

## Phase 5: Validation and Rollout

**Objective**: Ensure new strategy is practical and stable.

**Tasks**:
1. Validate each template path by executing baseline checks:
- `nix develop -c bash -lc 'mix --version'`
- `nix develop -c bash -lc 'mix deps.get && mix test'` (where applicable)

2. Validate direnv entry for at least one template.

3. Validate one OrbStack/NixOS-oriented flow and capture caveats.

4. Update cross-links:
- `docs/nix_flake_runbook.md`
- `README.md` (if needed)
- `docs/quickstart-agents.md` (if needed)

**Deliverable**:
- Verified docs + tested paths with explicit known limitations.

**Commit**:
- `docs: finalize nix strategy rollout and runbook cross-links`

---

## 5. Proposed File Plan

**Create**:
- `tools/nixos/README.md`
- `tools/nixos/nix.md`
- `tools/nixos/nixos.md`
- `tools/nixos/elixir_flakes.md`
- `scripts/init_project_v2.sh`
- `PROJECT_INIT_V2.md`
- `docs/plans/nix_strategy_local_elixir_projects_implementation_plan_2026-02-21.md` (this file)

**Update (as needed in rollout)**:
- `docs/nix_flake_runbook.md`
- `README.md`
- `docs/quickstart-agents.md`

**Leave unchanged (legacy retained)**:
- `scripts/init_project.sh`
- `PROJECT_INIT.md`

---

## 6. Research Summary for `elixir_flakes.md`

The following links should be included and classified in `tools/nixos/elixir_flakes.md` as "official", "community templates", or "advanced/experimental":

## User-provided references

1. Nix docker examples (nixpkgs):
- <https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/docker/examples.nix>

2. Template repositories:
- <https://github.com/akirak/flake-templates>
- Local copy: `/Users/elay14/projects/2026/flake-templates`
- <https://github.com/the-nix-way/dev-templates/blob/main/elixir/flake.nix>
- <https://github.com/liyangau/flake-templates>

3. NUR and ecosystem:
- <https://nur.nix-community.org/>

4. NixOps4:
- <https://github.com/nixops4/nixops4>
- <https://github.com/nixops4/nixops4-nixos/tree/main/example>

5. NixOS containers and macOS context:
- <https://nixos.wiki/wiki/NixOS_Containers>
- <https://www.tweag.io/blog/2023-02-09-nixos-vm-on-macos/>

6. Journey/blog references:
- <https://tech.aufomm.com/my-nix-journey-how-to-use-nix-to-set-up-dev-environment/>
- <https://tech.aufomm.com/my-nixos-journey-flakes/>

7. Video reference:
- <https://www.youtube.com/watch?v=_8xh5EcsHr>

## Additional references to include

1. Nix devshell command reference:
- <https://nix.dev/manual/nix/2.32/command-ref/new-cli/nix3-develop>

2. Nix flakes feature overview:
- <https://nix.dev/manual/nix/2.18/command-ref/new-cli/nix3-flake>

3. Nix language reference:
- <https://nix.dev/manual/nix/2.18/language/>

4. NixOS packages and options browser:
- <https://search.nixos.org/packages>
- <https://search.nixos.org/options>

5. nix-direnv:
- <https://github.com/nix-community/nix-direnv>

6. Determinate Nix installer/docs:
- <https://docs.determinate.systems/>

7. Nix templates discovery:
- <https://github.com/NixOS/templates>

---

## 7. Acceptance Criteria

1. `tools/nixos/elixir_flakes.md` contains copy-ready flakes for all required project types.
2. `tools/nixos/nix.md` clearly documents Determinate + direnv on macOS.
3. `tools/nixos/nixos.md` clearly documents OrbStack/NixOS workflows and limitations.
4. `scripts/init_project_v2.sh` exists and matches the new four-step initialization model.
5. `PROJECT_INIT_V2.md` provides an LLM-agnostic bootstrap guide.
6. Legacy files remain intact and explicitly marked as legacy in the new docs.
7. Git commit messages and branch workflow follow `git_rules.md` conventions.

---

## 8. Risks and Mitigations

1. Template drift across multiple flake examples.
- Mitigation: define shared base conventions and add a validation checklist.

2. macOS vs Linux behavior differences.
- Mitigation: include explicit per-platform notes and minimum tested paths.

3. Overfitting to one assistant tool.
- Mitigation: keep initialization and docs provider-neutral; add optional integration notes only.

4. Container workflow complexity.
- Mitigation: start with one validated path, then expand after proving reliability.

---

## 9. Decisions Needed Before Build Phase

1. Default pinned versions for Erlang/Elixir in v2 templates (stay on 1.17/OTP 27 or move forward).
2. Whether to introduce `flake-parts` now or keep plain flakes for readability.
3. Whether containerized devshell support is required-by-default or optional.
4. Which templates are mandatory in v1 of `elixir_flakes.md` versus phased-in later.

---

## 10. Recommended Execution Order

1. Complete Phase 1 docs skeleton in `tools/nixos/`.
2. Draft `elixir_flakes.md` with existing local configs as baseline.
3. Add external reference annotations and rationale for each link.
4. Build `init_project_v2.sh` + `PROJECT_INIT_V2.md`.
5. Validate with one Phoenix/Ash project and one Nerves project.
6. Update runbook/README links and finalize.
