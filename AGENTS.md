# Agent Guidelines for OpenCode

This document provides OpenCode-specific guidelines for AI agents working on Elixir/BEAM projects.

---

## Overview

OpenCode supports **multi-session agentic development** with specialized roles for each phase:
- **Plan Mode**: Architecture and design
- **Build Mode**: Implementation and coding
- **Review Mode**: Quality assurance and code review

### Agent Responsibilities

Each agent should:
1. **Read ai-rules guidelines** - Reference relevant roles, skills, and configs
2. **Follow git_rules.md** - Git workflow for all repository operations
3. **Follow project_requirements.md** - Project-specific configuration takes precedence
4. **Use appropriate tools** - mgrep, Serena, grep, git as configured for mode
5. **Maintain code quality** - OTP patterns, TDD, code quality checks
6. **Communicate clearly** - Explain actions, provide context, ask when needed

---

## OpenCode Modes

### Plan Mode (Architecture & Design)

**Configuration**: `.opencode/opencode.plan.json`

**Agent**: Architect

**Tools**:
- ✅ **mgrep**: Primary - Semantic codebase discovery
- ✅ **grep**: Exact pattern matching
- ✅ **websearch**: External best practices and documentation
- ❌ **write**: Disabled - Read-only planning
- ❌ **serena_***: Disabled - No editing needed

**Model Selection**:
- **Primary**: Claude 3.5 Sonnet (API) - Strong architectural reasoning
- **Fallback**: Claude 3 Opus
- **Local**: Llama 3.1 70B-instruct (Ollama/MLX)

**Responsibilities**:
1. Read `project_requirements.md` for project scope
2. Use mgrep to discover existing patterns in codebase
3. Design system architecture with OTP supervision trees
4. Define domain boundaries and resources
5. Create file structure plan
6. Document architecture decisions

**Output**:
- Updated `project_requirements.md` with architecture section
- File structure plan (lib/, test/, config/)
- Supervision tree design
- Domain/resource/action breakdown

**Boundaries**:
- ✅ Always read existing code before designing new structure
- ✅ Use mgrep for semantic discovery of patterns
- ✅ Design fault-tolerant systems with supervision
- ❌ Never create files in plan mode (read-only)
- ❌ Never run tests or make changes

---

### Build Mode (Implementation)

**Configuration**: `.opencode/opencode.build.json`

**Agent**: Orchestrator

**Tools**:
- ✅ **write**: Primary - Create and modify code
- ✅ **serena_*`: Primary - Semantic search + editing
- ✅ **grep**: Fast exact searches
- ⚠️ **mgrep**: Reference only - Quick lookups when needed
- ✅ **bash**: Run mix commands, tests

**Model Selection**:
- **Primary**: DeepSeek Coder 16B-instruct (Ollama) - Fast, good at code
- **Fallback**: Llama 3.1 70B-instruct
- **Local**: LM Studio Phi-4-mini for small edits

**Responsibilities**:
1. Read `project_requirements.md` for architecture and requirements
2. Implement features following Domain Resource Action pattern
3. Use Serena for semantic search + editing workflows
4. Follow TDD - Write failing tests first
5. Run `/create-feature` command for new features
6. Run `/full-test` before committing changes
7. Follow OTP best practices from roles/skills

**Output**:
- Complete implementation code (lib/, test/)
- ExUnit tests (passing)
- Ecto schemas and migrations
- OTP-compliant modules

**Boundaries**:
- ✅ Always write tests before implementation (TDD)
- ✅ Use Serena for semantic search + editing
- ✅ Follow plan from plan session
- ✅ Run `mix format`, `mix credo`, `mix test` before completion
- ❌ Never skip testing or commit failing tests
- ❌ Never ignore plan requirements

---

### Review Mode (Quality Assurance)

**Configuration**: `.opencode/opencode.review.json`

**Agent**: Reviewer + QA

**Tools**:
- ✅ **mgrep**: Active - Cross-reference analysis
- ✅ **serena_*`: Active - Edit context understanding
- ✅ **grep**: Quick pattern verification
- ❌ **write**: Disabled - Analysis only
- ✅ **bash**: Run quality checks (credo, dialyzer, coverage)

**Model Selection**:
- **Primary**: Claude 3.5 Sonnet (API) - Strong analysis
- **Fallback**: Claude 3 Opus
- **Local**: Llama 3.1 70B-instruct

**Responsibilities**:
1. Read `project_requirements.md` for quality requirements
2. Use mgrep for cross-referencing similar code patterns
3. Use Serena for understanding edit context
4. Review for OTP best practices
5. Check for N+1 query problems
6. Verify test coverage and test quality
7. Run code quality tools (Credo, Dialyzer)
8. Provide specific, actionable feedback

**Output**:
- Code review report with specific issues
- Test coverage analysis
- Recommendations for improvements
- Quality metrics (coverage, warnings, errors)

**Boundaries**:
- ✅ Always provide specific, actionable feedback
- ✅ Review OTP patterns and supervision
- ✅ Check for N+1 queries and performance issues
- ✅ Verify test coverage >80% (or project goal)
- ❌ Never nitpick style over substance
- ❌ Never approve code with failing tests

---

## Tool Usage Guidelines

### mgrep (Semantic Search)

**When to Use**:
- **Plan Mode**: Discover existing patterns, find similar implementations
- **Build Mode**: Quick reference when stuck (use sparingly)
- **Review Mode**: Cross-reference code for consistency

**Best Practices**:
- Use natural language queries: "where do we handle user authentication?"
- Use web search for external patterns: `--web "OTP GenServer patterns"`
- Limit results: `-m 20` for manageable output
- Show content: `-c` to see code snippets

**Example Queries**:
```
mgrep "Domain Resource Action examples in codebase"
mgrep -m 10 "GenServer callback patterns"
mgrep --web "Ash authentication best practices"
```

### Serena MCP (Semantic Search + Edit)

**When to Use**:
- **Build Mode**: Primary - Semantic search with editing capability
- **Review Mode**: Understand edit context for review suggestions

**Best Practices**:
- Use for multi-file refactors with context
- Leverage LSP integration for symbol navigation
- Read `.serena/` project config for customization
- Keep read_only: false for build mode, true for plan mode

**Integration**:
- Configured via `opencode_mcp.json`
- Project-specific settings in `.serena/` folder
- Uses uvx for execution (no installation needed)

### grep (Exact Pattern Matching)

**When to Use**:
- **Plan Mode**: Find exact function/module names
- **Build Mode**: Fast searches for specific patterns
- **Review Mode**: Verify exact matches exist

**Best Practices**:
- Use for known patterns: function names, module names, error messages
- Combine with mgrep for comprehensive search
- Prefer mgrep for semantic discovery, grep for exact matches

**Example Queries**:
```bash
# Find all GenServer modules
grep -r "use GenServer" lib/

# Find specific function
grep -r "def call(" lib/accounts/
```

### Bash (Commands)

**When to Use**:
- **Build Mode**: Run mix commands, tests
- **Review Mode**: Run quality checks

**Common Commands**:
```bash
mix compile        # Compile project
mix test           # Run tests
mix test --cover   # Run with coverage
mix format        # Format code
mix credo         # Code quality checks
mix dialyzer      # Type checking
```

---

## Agent Roles Integration

### Architect (Plan Mode)
**File**: `roles/architect.md`

**Invoke When**:
- Designing new systems or major subsystems
- Making architectural decisions
- Planning supervision trees

**Expertise**:
- OTP principles (supervision, processes)
- Domain Resource Action pattern
- System boundaries and fault tolerance

**Interactions**:
- Use mgrep to discover existing patterns
- Reference `skills/otp-patterns/` for patterns
- Consult `roles/database-architect.md` for schema design

### Orchestrator (Build Mode)
**File**: `roles/orchestrator.md`

**Invoke When**:
- Implementing features
- Coordinating TDD workflow
- Managing build process

**Expertise**:
- Implementation coordination
- Serena + mgrep tool usage
- TDD workflow management
- Code quality enforcement

**Interactions**:
- Read `project_requirements.md` for plan
- Use `/create-feature` command for new features
- Consult `roles/backend-specialist.md` for business logic
- Consult `roles/frontend-specialist.md` for LiveView
- Use `skills/test-generation/` for test writing

### Reviewer (Review Mode)
**File**: `roles/reviewer.md`

**Invoke When**:
- Reviewing code changes
- After implementing features
- Before merging to main

**Expertise**:
- OTP best practices verification
- Code quality analysis
- Specific, actionable feedback

**Interactions**:
- Use mgrep for cross-referencing
- Use Serena for edit context
- Consult `roles/qa.md` for testing review
- Use `skills/ecto-query-analysis/` for performance

### Git Specialist (All Modes)
**File**: `roles/git-specialist.md`

**Invoke When**:
- Initializing git repositories
- Setting up GitHub remotes and repositories
- Creating and merging pull requests
- Resolving merge conflicts
- Setting up Git submodules
- Configuring Git hooks and automation

**Expertise**:
- Git repository management and configuration
- GitHub CLI (`gh`) automation
- Feature branch workflows and PR management
- Git submodules and monorepo patterns
- Merge conflict resolution
- Repository security and access control

**Interactions**:
- Follow `git_rules.md` for all git operations
- Use `skills/git-workflow/` for git automation
- Create PRs for code review before merging
- Reference Git Specialist role when needed in Build Mode
- Use gh CLI for repository automation

---

## Quality Standards

### Code Quality (All Modes)
- **Formatting**: Run `mix format` before completion
- **Static Analysis**: Run `mix credo --strict`
- **Type Checking**: Run `mix dialyzer` (if configured)
- **Documentation**: Add `@moduledoc` and `@doc` to public functions

### OTP Best Practices
- **Supervision**: Named processes, clear restart strategies
- **GenServer**: Separate client/server APIs, avoid blocking callbacks
- **State Management**: Use GenServer/Agent for state, plain functions for pure logic
- **Error Handling**: Use pattern matching, "let it crash" philosophy

### Testing Standards
- **TDD**: Write tests before implementation
- **Coverage**: Aim for 80%+ on business logic
- **Test Types**:
  - Unit tests for pure functions
  - Integration tests for database/API
  - Property-based tests for complex logic
  - E2E tests for critical user journeys

### Elixir Idioms
- **Pattern Matching**: Use instead of conditionals
- **Pipe Operator**: Transform data with `|>`
- **Comprehensions**: Use for data transformation
- **Immutable Data**: Never mutate, always transform

---

## Common Patterns

### Domain Resource Action Implementation
```elixir
# 1. Define schema (database/architect role)
defmodule Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> put_password_hash()
  end
end

# 2. Define action (orchestrator role)
defmodule Accounts.User.Create do
  alias Accounts.{User, Repo}

  @spec call(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def call(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end
end

# 3. Define API (orchestrator role)
defmodule Accounts.User do
  use Ash.Resource

  actions do
    create :create
    read :read
    update :update
    destroy :destroy
  end
end
```

### GenServer Implementation
```elixir
# Client API
defmodule Cache.Worker do
  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def get(key), do: GenServer.call(__MODULE__, {:get, key})
  def put(key, value), do: GenServer.cast(__MODULE__, {:put, key, value})

  # Server Callbacks
  @impl true
  def init(opts), do: {:ok, %{cache: %{}, opts: opts}}

  @impl true
  def handle_call({:get, key}, _from, state) do
    {:reply, Map.get(state.cache, key), state}
  end

  @impl true
  def handle_cast({:put, key, value}, state) do
    {:noreply, put_in(state.cache[key], value)}
  end
end
```

### Test Implementation (TDD)
```elixir
# Red: Write failing test
defmodule Accounts.User.CreateTest do
  use Accounts.DataCase

  test "creates user with valid attributes" do
    attrs = %{email: "test@example.com", password: "password123"}
    assert {:ok, %User{} = user} = Accounts.User.Create.call(attrs)
    assert user.email == "test@example.com"
    refute user.password  # Password should be hashed
  end
end

# Green: Make test pass (implementation)
defmodule Accounts.User.Create do
  def call(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end
end

# Refactor: Improve with confidence
defmodule Accounts.User.Create do
  def call(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> put_password_hash()
    |> Repo.insert()
  end

  defp put_password_hash(changeset) do
    case get_change(changeset, :password) do
      {nil, _} -> changeset
      {password, changeset} ->
        hash = Bcrypt.hash_pwd(password)
        put_change(changeset, :password_hash, hash)
    end
  end
end
```

---

## Troubleshooting

### Plan Mode Issues

**Issue**: mgrep returns no results
**Solution**:
- Check if codebase is indexed (run `mgrep watch` first)
- Use broader natural language queries
- Try exact search with grep

**Issue**: Plan doesn't match project requirements
**Solution**:
- Re-read `project_requirements.md`
- Ask for clarification on unclear requirements
- Use `--web` flag with mgrep for external patterns

### Build Mode Issues

**Issue**: Serena MCP not available
**Solution**:
- Check `opencode_mcp.json` configuration
- Verify uv is installed: `uv --version`
- Test Serena: `uvx serena start-mcp-server --help`

**Issue**: Tests failing
**Solution**:
- Run `mix test --trace` for detailed output
- Check test setup and fixtures
- Verify database migrations are applied
- Review implementation against tests

**Issue**: Code quality checks fail
**Solution**:
- Run `mix format` to fix formatting
- Address Credo warnings one by one
- Fix Dialyzer type mismatches

### Review Mode Issues

**Issue**: mgrep slow on large codebase
**Solution**:
- Limit results with `-m 20`
- Search specific directories instead of entire codebase
- Use grep for exact patterns

**Issue**: Serena provides too much context
**Solution**:
- Adjust `.serena/project.yml` settings
- Limit file types indexed
- Use read-only mode for analysis

---

## Integration with Other Tools

### Claude Code / Claude Desktop
- **Compatible**: Yes, via `.claude/` folder structure
- **Configuration**: See `tools/claude/README.md`
- **Usage**: Same roles and skills apply

### Cursor
- **Compatible**: Yes, via `.cursorrules` file
- **Configuration**: See `tools/cursor/README.md`
- **Usage**: Use cursor's agent features with ai-rules guidelines

---

## Summary

OpenCode agents should:

1. **Follow mode-specific guidelines** - Plan, Build, Review
2. **Use tools appropriately** - mgrep (plan/review), Serena (build/review)
3. **Reference ai-rules** - Roles, skills, project requirements
4. **Maintain quality** - OTP patterns, TDD, code quality checks
5. **Communicate clearly** - Explain actions, provide context

This ensures consistent, high-quality Elixir/BEAM development across all modes.
