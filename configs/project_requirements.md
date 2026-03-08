# Project Requirements

Use this file as the project brief that agents read before planning or coding. Keep it concise, current, and specific to the application you are building.

**Project Name**:
**Created**:
**Last Updated**:
**Primary Owner**:

---

## 1. Project Overview

**What are you building?**

**Who is it for?**

**What problem does it solve?**

**Key features in scope for the next milestone**:
-
-
-

**Out of scope for now**:
-
-

---

## 2. Technical Stack

**Project Type**: Phoenix app / Phoenix + Ash / Elixir library / Nerves / other

**Elixir / OTP target**:

**Core frameworks and libraries**:
- Phoenix:
- Ash:
- LiveView:
- Database:
- HTTP client:
- Background jobs:
- Observability:

**Deployment target**:

**Environment constraints**:
- Nix required?: yes / no
- Local-first development?: yes / no
- External paid services allowed?: yes / no

---

## 3. LLM Configuration

Choose tools and models that fit your budget, privacy needs, and latency tolerance. Prefer current, reliable models over hard-coding stale recommendations.

### 3.1 Planning

**Primary provider/model**:

**Fallback provider/model**:

**Local option, if any**:

**Why this choice**:

### 3.2 Build

**Primary provider/model**:

**Fallback provider/model**:

**Local option, if any**:

**Why this choice**:

### 3.3 Review

**Primary provider/model**:

**Fallback provider/model**:

**Local option, if any**:

**Why this choice**:

### 3.4 Provider Constraints

**Required environment variables**:
-

**Budget / privacy / data handling constraints**:
-

For selection guidance, see `configs/project_requirements_appendix.md`.

---

## 4. Tool Configuration

Document the tools you expect agents to rely on for this project.

### 4.1 Planning Tools

- `rg` / exact search:
- `mgrep` / conceptual search:
- `web search`:
- `usage_rules`:
- `codicil`:
- `Serena`:

### 4.2 Build Tools

- `rg` / exact search:
- `Serena`:
- `mgrep`:
- `bash` / `mix` tasks:
- formatter / static analysis:

### 4.3 Review Tools

- `rg` / exact search:
- `mgrep`:
- `Serena`:
- review-specific checks:

### 4.4 Tool Notes

- Preferred workflow: single session / multi-session
- Required local services:
- MCP servers in use:

---

## 5. Architecture Requirements

### 5.1 Design Direction

- Domain boundaries:
- Core business entities:
- Primary workflows:
- Data ownership rules:

### 5.2 BEAM / OTP Expectations

- Supervision strategy:
- Long-running processes:
- PubSub / realtime needs:
- Fault tolerance expectations:

### 5.3 Web / API Shape

- LiveView usage:
- JSON API / GraphQL / internal APIs:
- Authn / authz approach:
- External integrations:

### 5.4 Data and Persistence

- Database choice:
- Caching strategy:
- Eventing / jobs:
- Migration constraints:

---

## 6. Testing Strategy

**Required checks before merge**:
- `mix format`
- `mix credo --strict`
- `mix test`

**Optional checks**:
- `mix dialyzer`
- property-based tests
- integration or live tests

**Coverage priorities**:
- Critical user flows:
- Business logic:
- OTP/process behavior:
- External integrations:

**Testing rules**:
- Prefer deterministic tests.
- Avoid sleep-based synchronization.
- Mirror source structure in tests where practical.

---

## 7. Development Workflow

**Working mode**: plan/build/review or single-session

**Branching / review expectations**:
- Feature branches:
- PR required before merge?: yes / no
- Conventional commits?: yes / no

**Definition of done**:
-
-
-

---

## 8. Performance, Reliability, and Security

**Performance priorities**:
-

**Reliability expectations**:
-

**Security constraints**:
-

**Observability requirements**:
-

---

## 9. Open Questions

-
-
-

---

## 10. Initial Delivery Plan

**Slice 1**:

**Slice 2**:

**Slice 3**:
