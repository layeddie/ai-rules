# Skills Overview

`.ai_rules` provides **reusable technical skills** that can be invoked by any agent role.

---

## Overview

Skills are **focused technical modules** with specialized expertise in specific Elixir/BEAM areas.

### Key Features

- **Reusable**: Can be invoked by any agent (Architect, Orchestrator, Reviewer, QA, etc.)
- **Specialized**: Each skill focuses on a specific domain (OTP, Ecto, Testing)
- **Actionable**: Provides concrete code examples and patterns
- **Best Practices**: Includes anti-patterns and recommendations

---

## Available Skills

### otp-patterns

**Purpose**: Implementing OTP design patterns including GenServer, Supervisor, and Application behaviors.

**Expertise**:
- GenServer patterns (client/server separation, naming)
- Supervisor strategies (one_for_one, one_for_all, dynamic)
- Registry usage for dynamic process naming
- Application supervision trees

**When to Use**:
- Creating new GenServers or Supervisors
- Designing supervision trees
- Implementing process-based features
- Fault tolerance and restart strategies

**Invoked By**:
- Architect (system design)
- Orchestrator (implementation coordination)
- Reviewer (verifying OTP patterns)

---

### ecto-query-analysis

**Purpose**: Analyzing Ecto queries for N+1 problems, missing preloads, and performance issues.

**Expertise**:
- N+1 query identification and prevention
- Ecto preload strategies (associations, selective, custom)
- Query optimization (window functions, aggregation)
- Missing index detection
- Database performance tuning

**When to Use**:
- Reviewing Ecto query code
- Investigating slow database queries
- Optimizing database access patterns
- Designing schemas for performance

**Invoked By**:
- Database Architect (schema design and optimization)
- Reviewer (identifying performance issues)
- QA (testing query performance)

---

### test-generation

**Purpose**: Generating comprehensive Elixir tests using ExUnit following TDD principles.

**Expertise**:
- TDD workflow (Red, Green, Refactor)
- ExUnit test patterns (unit, integration, E2E, property-based)
- GenServer testing (through client API)
- Property-based testing (StreamData, PropCheck)
- Test organization and coverage analysis

**When to Use**:
- Writing tests for new features
- Creating test strategies for complex logic
- Implementing property-based tests for edge cases
- Designing test coverage goals and metrics

**Invoked By**:
- Orchestrator (TDD coordination)
- QA (test strategy and coverage analysis)
- Any agent (when writing tests for implementation)

---

## Skill Structure

Each skill follows a consistent structure:

```
skills/
├── otp-patterns/
│   ├── SKILL.md           # Main skill documentation
│   └── examples/              # Code examples
├── ecto-query-analysis/
│   ├── SKILL.md           # Main skill documentation
│   └── examples/              # Code examples
└── test-generation/
    ├── SKILL.md           # Main skill documentation
    └── examples/              # Code examples
```

---

## Usage

### In Agent Prompts

Agents can invoke skills directly:

```text
"Use otp-patterns skill to implement a GenServer for this cache feature."
```

```text
"Use ecto-query-analysis skill to check for N+1 queries in this user list."
```

```text
"Use test-generation skill to write comprehensive tests for user registration."
```

### In Role Files

Roles reference relevant skills for specific tasks:

- **Architect**: References `otp-patterns` for system design
- **Orchestrator**: References `test-generation` for TDD workflow
- **Database Architect**: References `ecto-query-analysis` for query optimization
- **Reviewer**: References all skills for verifying best practices
- **QA**: References `test-generation` for test strategy

---

## Skill Patterns

Each skill provides:

### 1. Clear Purpose
- What the skill does
- When to use it
- What expertise it provides

### 2. Code Examples
- Best practice implementations
- Anti-patterns to avoid
- Real-world use cases

### 3. Best Practices
- How to use the pattern correctly
- Common pitfalls and how to avoid them
- When to choose alternative patterns

### 4. Integration

- How this skill works with other skills
- Interaction with different roles
- Tool dependencies (if any)

---

## Best Practices

### Do

✅ Reference specific skills when appropriate
✅ Use code examples from skills as starting points
✅ Adapt patterns to your project context
✅ Follow skill's best practices and anti-patterns
✅ Provide feedback on skill improvements

### Don't

❌ Ignore skill's purpose and expertise
❌ Use patterns outside their intended scope
❌ Skip reading skill documentation
❌ Implement anti-patterns from skills

---

## Summary

`.ai_rules` skills provide:

✅ **Reusable technical modules** for common Elixir/BEAM patterns
✅ **Specialized expertise** in OTP, Ecto, and Testing
✅ **Actionable** with code examples and best practices
✅ **Flexible** - Can be invoked by any agent role
✅ **Well-documented** with clear purpose and usage guidelines

**For detailed information**, see individual skill documentation.

---

**Skills complement roles** by providing specialized technical patterns that agents can leverage for consistent, high-quality code.
