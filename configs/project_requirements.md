# Project Requirements

**Project Name**: Test Elixir/Ash/Phoenix/LiveView Project
**Created**: [Date]
**Language**: Elixir 1.17+
**Framework**: Phoenix 1.7.14+, Ash 3.4+, LiveView 1.0.0+
**Database**: PostgreSQL 16
**Testing Framework**: ExUnit, StreamData, PropCheck
**LiveView Version**: Phoenix LiveView 1.0.0+

---

## 1. Project Overview

**Purpose**: Test project for validating `ai-rules` repository with Elixir, Ash, Phoenix, and LiveView integration.

**Target Users**: Developers testing `ai-rules` repository for compatibility with OpenCode, mgrep, and Serena MCP.

**Key Features**:
- Domain Resource Action pattern with Ash framework
- LiveView UI for real-time features
- OTP supervision tree architecture
- TDD workflow with comprehensive testing
- mgrep + Serena MCP integration
- Multi-session development workflow (plan, build, review)

---

## 2. Technical Stack

**Elixir Version**: 1.17.3
**Phoenix Version**: 1.7.14
**Ash Version**: 3.4.12
**Ash Dependencies**:
- `ash`: Core Ash framework
- `ash_postgres`: PostgreSQL adapter
- `ash_authentication`: JWT authentication
- `ash_phoenix`: Phoenix LiveView integration
- `ash_json_api`: JSON API layer
- `ash_policy`: Authorization policies
- `ash_graphql`: GraphQL support (optional)

**Database**: PostgreSQL 16 via Ash Postgres

**Testing Framework**: 
- `ex_unit`: Built-in testing framework
- `stream_data`: Property-based testing
- `propcheck`: Alternative property-based testing
- `ex_machina`: ExMachina for concurrent testing (optional)

**LiveView**: Phoenix LiveView 1.0.0+

**Additional Libraries**:
- `jason`: JSON parsing
- `phoenix_live_view`: LiveView framework
- `telemetry`: Observability and metrics
- `gettext`: Internationalization

**Development Tools**:
- `credo`: Code quality and static analysis
- `dialyxir`: Type checking (optional)
- `ex_doc`: Documentation generation

---

## 3. LLM Configuration

Detailed model matrices are in `configs/project_requirements_appendix.md`. Use that appendix to select providers/models; keep this file lean for agent context.

---

## 4. Tool Configuration

### 4.1 Planning Tools

**mgrep**: ✅ Enabled
- **Purpose**: Semantic codebase discovery
- **Configuration**: 
  - Max results: 20
  - Web search: Enabled
  - Content view: Enabled
- **Usage**: Primary tool for discovering patterns

**Tidewave MCP**: ⏸️ Disabled
- **Reason**: Subscription required, using subscription-free starting point

**Serena MCP**: ❌ Disabled
- **Reason**: Planning phase is read-only

**grep**: ✅ Enabled
- **Purpose**: Exact pattern matching for known patterns
- **Usage**: Finding exact function/module names

**websearch**: ✅ Enabled
- **Purpose**: External best practices and documentation
- **Usage**: Finding external patterns, OTP best practices

### 4.2 Build Tools

**mgrep**: ⚠️ Reference only
- **Purpose**: Quick lookups during implementation
- **Configuration**: Disabled by default, enable with --mgrep flag if needed
- **Usage**: When stuck or need quick reference

**Tidewave MCP**: ⏸️ Disabled
- **Reason**: Subscription required, using subscription-free starting point

**Serena MCP**: ✅ Enabled
- **Purpose**: Semantic search + editing with context
- **Configuration**:
  - Read-only: false
  - Project path: `.serena/`

**grep**: ✅ Enabled
- **Purpose**: Fast exact searches during implementation
- **Usage**: Finding exact patterns, verifying matches

**websearch**: ⚠️ Disabled
- **Purpose**: External search (less needed in build mode)
- **Usage**: Disabled to reduce context

**bash**: ✅ Enabled
- **Purpose**: Run mix commands, tests, quality checks
- **Usage**: 
  - `mix deps.get`
  - `mix test`
  - `mix format`
  - `mix credo --strict`
  - `mix dialyzer`

**write**: ✅ Enabled
- **Purpose**: Create and modify code files
- **Usage**: All implementation operations

---

## 5. Architecture Requirements

### 5.1 Design Patterns

**Domain Resource Action**: ✅ Yes
- **Use Case**: Primary pattern for organizing business logic

**OTP Supervision Tree**: ✅ Yes
- **Strategy**: One-for-one for domain supervisors
- **Rationale**: Isolation between domains, independent failure handling

### 5.2 System Boundaries

**Domains**:
- **accounts**: User management, authentication, sessions
- **dashboard**: LiveView UI, real-time features
- **api**: JSON API endpoints via Ash JSON API
- **notifications**: Email notifications (Swoosh)
- **background**: Background job processing

**APIs**:
- **Internal**: Phoenix LiveView channels
- **External**: Third-party integrations

---

## 6. Testing Strategy

**Unit Testing**: 80%+ coverage on business logic
- **Integration Testing**: 30%+ coverage on database/API
- **Property-Based Testing**: Yes, for complex logic
- **E2E Testing**: Critical user journeys

**Test Organization**:
```
test/
├── test_app_web/
│   ├── [Project Name]/
│   │   ├── accounts/
│   │   │   └── user/
│   │       └── actions/
│   └── dashboards/
├── test_app_web/
└── test/[Project Name]/
    └── live/
```

### Test Coverage Goals**:
- **Business Logic**: 80%+
- **Domain Modules**: 85%+
- **Integration Points**: 90%+
- **Critical Paths**: 100%

---

## 7. Development Workflow

**Mode Strategy**: Multi-session (plan in one term, build in another, automatic but other options available)

**CI/CD**: GitHub Actions
```yaml
name: Test and Coverage

on:
  pull_request:
    jobs:
      - name: Run tests and coverage
        runs-on: ubuntu-latest
    steps:
      - name: Install dependencies
      - name: Check out code and install
      - name: Run all tests
      - name: Generate coverage report
      - name: Upload coverage report
```

**Code Review**: Required before merging to main

**Deployment**: Mix release for OTP application

---

## 8. Performance & Scaling

**Concurrency Model**: OTP processes with Task.async for fire-and-forget

**Database Optimization**:
- Preloading strategies
- Window functions for aggregation
- Indexing: Composite indexes on frequently queried columns

**Horizontal Scaling**: Phoenix PubSub for distributed updates

**Caching Strategy**: ETS for in-memory caches

---

## 9. Security Requirements

**Authentication**: Ash Authentication with JWT tokens
- **Authorization**: Ash policies with role-based access control (RBAC)

**Data Encryption**: 
- **At rest**: TLS/HTTPS
- **In transit**: TLS (for internal services)

**Input Validation**: Ash changesets with proper validations

**Sensitive Data**: Never log or expose sensitive data

---

## 10. Deployment & DevOps

**Environment**: Development, Staging, Production

**Release Strategy**: Blue-green deployment
- **Monitoring**: Telemetry for observability

**Health Checks**: `/health` endpoint for system status

---

## 11. Project Structure

```
test_app/
├── ai-rules/                # Symlink to this repo
├── .opencode/               # Plan/Build/Review configs
├── config/                  # Environment config only
├── lib/
│   ├── test_app/            # Application + supervision
│   │   ├── application.ex
│   │   ├── registry/
│   │   └── support/
│   └── test_app_ash/        # Ash Domain/Resource/Action (single responsibility)
│       ├── domains/
│       │   └── accounts/
│       │       ├── resources/
│       │       ├── actions/
│       │       ├── policies/
│       │       └── notifiers/
│       └── apis/
├── lib/test_app_web/        # Phoenix LiveView (thin glue)
│   ├── endpoint.ex
│   ├── router.ex
│   ├── controllers/
│   └── live/
├── priv/repo/               # Migrations & seeds
├── test/                    # Mirrors lib/ for coverage/searchability
│   ├── support/
│   ├── ash/
│   └── web/
├── flake.nix                # Nix devshell
└── project_requirements.md  # This file
```

---

## 12. Acceptance Criteria

- [ ] Project initialized with ai-rules and all required directories created
- [ ] project_requirements.md configured with Elixir, Ash, Phoenix, LiveView
- [ ] LLM configuration defined for plan/build/review modes
- [ ] Tool configuration complete (mgrep + Serena per phase)
- [ ] Nix configuration ready (MLX GPU config for M2 Max)
- [ ] Templates applied (Phoenix + Ash + LiveView)
- [ ] Multi-session workflow documented

---

## 13. Open Questions

- [ ] How to enable Tidewave MCP for testing? (requires subscription)
- [ ] What performance characteristics does Serena provide vs mgrep?
- [ ] Serena vs mgrep: Better LSP integration or faster performance?
- [ ] Should Serena be used in plan mode instead of read-only?
- [ ] How to optimize MLX GPU settings for this project?

---

## 14. Tidewave MCP (Pending Discussion)

**Status**: ⏸️ Awaiting decision before enabling in test project

**Questions to Resolve**:
1. What specific capabilities does Tidewave provide that Serena doesn't?
2. Should Tidewave be used instead of Serena, or in addition to Serena?
3. What are the performance characteristics (speed, accuracy, token usage)?
4. Does Tidewave have better LSP integration with OpenCode?
5. Is Tidewave more suitable for specific phases (plan/build/review)?
6. What are the subscription costs and model requirements?

**Current Placeholder Configuration**:
```json
{
  "mcp": {
    "tidewave": {
      "type": "local",
      "command": ["tidewave", "mcp"],
      "enabled": false,
      "environment": {
        "TIDEWAVE_PROJECT_PATH": "{project_root}/.tidewave",
        "TIDEWAVE_READ_ONLY": "true"
      }
    }
  }
}
```

**Recommendation**: Tidewave requires a subscription so `.ai_rules` is a **subscription-free starting point**. Consider whether to add Tidewave support after evaluating:
- **Subscription costs**
- **Performance comparison**
- **Integration benefits**
- **Suitability for specific use cases

---

**Ready for testing .ai_rules integration with OpenCode, mgrep, and Serena MCP!**
