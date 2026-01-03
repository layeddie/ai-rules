# Roles Overview

`.ai_rules` provides **role-based agents** with specialized expertise for different aspects of Elixir/BEAM development.

---

## Role Philosophy

Each role represents a **specialized expert** with:
- **Purpose**: Clear responsibility and when to invoke
- **Persona**: Professional background and expertise level
- **BEAM/Elixir Expertise**: Language-specific knowledge
- **When to Invoke**: Specific scenarios where this role excels
- **Key Responsibilities**: Core tasks this role handles
- **Decision Framework**: How the role makes decisions
- **Standards**: Patterns, anti-patterns, and best practices
- **Boundaries**: Always do, ask first, never do
- **Integration**: How this role works with others

---

## Available Roles

### Architecture & Planning

#### Architect (architect.md)
**Purpose**: System architecture and technical design

**Expertise**:
- OTP application design (supervision trees, process hierarchies)
- Domain Resource Action pattern application
- System boundaries and fault tolerance
- Technology stack decisions

**When to Invoke**:
- Designing new systems or major subsystems
- Making architectural decisions about process structure
- Evaluating technology choices or patterns
- Refactoring existing architecture
- Planning for scalability and performance
- Defining system boundaries and module organization

**Use In**: **Plan Session** (OpenCode plan mode)

---

### Implementation & Coordination

#### Orchestrator (orchestrator.md)
**Purpose**: Implementation coordinator and TDD workflow management

**Expertise**:
- TDD coordination (Red, Green, Refactor cycle)
- Domain Resource Action implementation
- Serena + mgrep tool usage
- Code quality enforcement
- Build process management

**When to Invoke**:
- Implementing features and functionality
- Coordinating TDD workflow
- Managing build process and quality checks
- Writing tests before implementation (TDD)
- Following architectural plan from Architect

**Use In**: **Build Session** (OpenCode build mode)

---

### Domain-Specific Specialists

#### Backend Specialist (backend-specialist.md)
**Purpose**: API design and business logic implementation

**Expertise**:
- Ash resources and API design
- Business logic implementation
- REST API best practices
- Error handling and validation

**When to Invoke**:
- Designing API endpoints
- Implementing business logic
- Creating Ash resources and actions
- Working with database layer

**Use In**: **Build Session** (OpenCode build mode)

#### Frontend Specialist (frontend-specialist.md)
**Purpose**: LiveView UI and real-time features

**Expertise**:
- Phoenix LiveView patterns
- Real-time UI with Phoenix PubSub
- Component design and organization
- Accessibility and UX considerations

**When to Invoke**:
- Building LiveView interfaces
- Implementing real-time features
- Designing UI components
- Working with web sockets

**Use In**: **Build Session** (OpenCode build mode)

#### Database Architect (database-architect.md)
**Purpose**: Ecto schema design and database optimization

**Expertise**:
- Ecto schema patterns and migrations
- Query optimization (N+1 prevention)
- Indexing strategies
- Database performance tuning

**When to Invoke**:
- Designing database schemas
- Creating migrations
- Optimizing database queries
- Analyzing slow queries
- Setting up indexes

**Use In**: **Build Session** (OpenCode build mode) or **Review Session** for optimization analysis

---

### Quality Assurance

#### QA (qa.md)
**Purpose**: Testing strategy, coverage analysis, and quality assurance

**Expertise**:
- ExUnit testing patterns
- Property-based testing (StreamData, PropCheck)
- Test coverage analysis
- Testing concurrent systems
- Integration and E2E testing

**When to Invoke**:
- Designing test strategies
- Writing comprehensive tests
- Analyzing test coverage
- Testing OTP processes
- Validating acceptance criteria

**Use In**: **Review Session** (OpenCode review mode) or any session for test writing

#### Reviewer (reviewer.md)
**Purpose**: Code review and best practices verification

**Expertise**:
- OTP pattern verification
- Code quality analysis (Credo, Dialyzer)
- Elixir idiomatic code
- Specific, actionable feedback

**When to Invoke**:
- Reviewing code changes
- Verifying best practices adherence
- Checking for anti-patterns
- Providing recommendations
- Quality assurance before merging

**Use In**: **Review Session** (OpenCode review mode)

---

## Role Interaction Patterns

### Typical Multi-Session Workflow

```
Plan Session (Architect)
    ↓ Designs architecture and file structure
    ↓
Build Session (Orchestrator)
    ↓ Implements features with TDD
    ↓
Review Session (Reviewer + QA)
    ↓ Verifies quality and test coverage
```

### Role Transitions

**Architect → Orchestrator**:
- Architect creates plan with file structure and supervision tree
- Orchestrator reads `project_requirements.md` and implements according to plan
- Use mgrep to discover patterns during planning
- Use Serena to implement with context during building

**Orchestrator → Reviewer + QA**:
- Orchestrator implements features with TDD
- Reviewer verifies OTP patterns and code quality
- QA checks test coverage and test quality
- Use mgrep for cross-referencing during review
- Use Serena to understand edit context

**All Roles → Frontend Specialist / Database Architect**:
- Domain-specific specialists consulted when needed
- Backend Specialist works with API design and business logic
- Frontend Specialist implements LiveView UI
- Database Architect optimizes queries and schema

---

## Role Selection Guide

### By Phase

| Phase | Primary Role | Supporting Roles |
|--------|----------------|-------------------|
| **Plan** | Architect | None (read-only) |
| **Build** | Orchestrator | Backend Specialist, Frontend Specialist, Database Architect |
| **Review** | Reviewer + QA | None (analysis only) |

### By Task Type

| Task Type | Recommended Role | Reason |
|-----------|------------------|---------|
| System Architecture | Architect | Focuses on design, OTP patterns |
| Feature Implementation | Orchestrator | Coordinates TDD workflow |
| API Design | Backend Specialist | Ash resources, REST patterns |
| LiveView UI | Frontend Specialist | Real-time UI, PubSub |
| Database Optimization | Database Architect | N+1 prevention, indexing |
| Test Strategy | QA | ExUnit, property-based testing |
| Code Review | Reviewer | Best practices, OTP verification |

---

## Role Configuration

### Default Role Per Mode

**Plan Mode**:
- **Primary Role**: Architect
- **Supporting**: None
- **Focus**: Architecture and design, read-only

**Build Mode**:
- **Primary Role**: Orchestrator
- **Supporting**: Backend Specialist, Frontend Specialist, Database Architect
- **Focus**: Implementation, TDD, code quality

**Review Mode**:
- **Primary Roles**: Reviewer + QA
- **Supporting**: None
- **Focus**: Quality assurance, analysis

### Customizing Role Selection

You can customize role selection in `project_requirements.md`:

```markdown
## Agent Configuration

### Plan Mode
**Primary Role**: Architect
**Supporting Roles**: None

### Build Mode
**Primary Role**: Orchestrator
**Supporting Roles**: Backend Specialist, Frontend Specialist

### Review Mode
**Primary Roles**: Reviewer + QA
**Supporting Roles**: None
```

---

## Integration with Skills

All roles can invoke **technical skills** from `.ai_rules/skills/`:

### Common Skills Used Across Roles

- **otp-patterns**: Used by Architect, Orchestrator, Reviewer for OTP implementations
- **ecto-query-analysis**: Used by Database Architect, Reviewer for query optimization
- **test-generation**: Used by QA, Orchestrator for test writing

### Skill Invocation

Agents can invoke skills directly:

```text
"Use otp-patterns skill to implement a GenServer for this cache feature."
```

```text
"Use test-generation skill to write comprehensive tests for user registration."
```

```text
"Use ecto-query-analysis skill to check for N+1 queries in this user list."
```

---

## Best Practices

### When Using Roles

**Do**:
- ✅ Invoke appropriate role for the task
- ✅ Read role documentation for guidance
- ✅ Follow role's boundaries and standards
- ✅ Use role's decision framework
- ✅ Communicate clearly when invoking different roles

**Don't**:
- ❌ Mix responsibilities (e.g., ask Architect to implement code)
- ❌ Ignore role's expertise and guidelines
- ❌ Skip reviewing role documentation
- ❌ Invoke wrong role for the task

### Role Collaboration

**Do**:
- ✅ Reference other roles when appropriate
- ✅ Document transitions between roles
- ✅ Respect architectural decisions from Architect
- ✅ Provide feedback to other roles when needed

**Don't**:
- ❌ Make decisions without consulting relevant roles
- ❌ Override architectural decisions without justification
- ❌ Ignore dependencies between roles

---

## Summary

`.ai_rules` provides a complete set of **role-based agents** for Elixir/BEAM development:

**Architecture**: Architect - System design and OTP patterns
**Implementation**: Orchestrator - TDD coordination and building
**Domain Specialists**:
- Backend Specialist - API and business logic
- Frontend Specialist - LiveView UI and real-time features
- Database Architect - Ecto schema and optimization

**Quality Assurance**:
- QA - Testing strategy and coverage
- Reviewer - Code review and best practices

**Integration**:
- Skills: otp-patterns, ecto-query-analysis, test-generation
- Tools: mgrep, Serena, grep
- Configs: project_requirements.md, tool-specific configs

**Multi-Session Workflow**: Plan → Build → Review with role-specific expertise in each phase

---

**For detailed role information**, see individual role files in this directory.
