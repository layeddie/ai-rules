# Project Initialization Guide

This guide walks through starting a new Elixir/BEAM project with `ai-rules` standards using OpenCode multi-session workflow.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initialization](#initialization)
3. [Project Configuration](#project-configuration)
4. [Multi-Session Setup](#multi-session-setup)
5. [Development Workflow](#development-workflow)
6. [Common Issues](#common-issues)
7. [Next Steps](#next-steps)

---

## Prerequisites

### Required Software

#### 1. Elixir & OTP
```bash
# Check Elixir version (must be 1.17+)
elixir --version

# Check OTP version (must be 26+)
erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell
```

**Install if needed**:
```bash
# Using Homebrew (macOS)
brew install elixir

# Using asdf (recommended)
asdf plugin-add elixir
asdf install erlang 27
asdf install elixir 1.17.3
asdf global erlang 27
asdf global elixir 1.17.3
```

#### 2. OpenCode
```bash
# Install OpenCode
curl -fsSL https://opencode.ai/install | bash

# Verify installation
opencode --version
```

#### 3. Git
```bash
# Check git version (must be 2.0+)
git --version
```

#### 4. Nix (Optional but Recommended)
```bash
# Check Nix version
nix --version

# Install if needed (macOS)
curl -L https://nixos.org/nix/install | sh
```

### Optional Software (for full functionality)

#### 1. mgrep (Semantic Search)
```bash
# Install Node.js first if needed
brew install node

# Install mgrep
npm install -g @mixedbread/mgrep

# Install for OpenCode
mgrep install-opencode

# Verify installation
mgrep --version
```

#### 2. uv & Serena MCP (Semantic Search + Edit)
```bash
# Install uv (Python package manager)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Test Serena MCP (no installation needed, runs via uvx)
uvx --from git+https://github.com/oraios/serena serena start-mcp-server --help
```

#### 3. Local LLM Providers (Optional but Recommended)

**Ollama**:
```bash
# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Pull recommended models
ollama pull llama3.1:70b-instruct
ollama pull deepseek-coder-v2:16b
ollama pull phi-4-mini

# Start Ollama
ollama serve
```

**LM Studio**:
```bash
# Download and install from https://lmstudio.ai/
# Start LM Studio
# Note the API endpoint (usually http://localhost:1234/v1)
```

---

## Initialization

### Step 1: Create Project

```bash
# Navigate to your projects directory
cd <your-projects-directory>

# Create new project with ai-rules
bash ai-rules/scripts/init_project.sh my_app
```

**What This Does**:
1. Creates project directory: `my_app/`
2. Initializes git repository
3. Creates symlink to `ai-rules`
4. Copies `project_requirements.md` template
5. Creates `.opencode/` directory with configurations
6. Creates basic file structure
7. Generates `.gitignore`
8. Creates initial git commit

**Optional: Specify Template**
```bash
# Available templates:
# - phoenix-ash-liveview (default)
# - phoenix-basic
# - elixir-library
# - nerves

# Example: Use Phoenix basic template
bash ai-rules/scripts/init_project.sh my_app ~/path/to/ai-rules phoenix-basic

# Example: No template (minimal structure)
bash ai-rules/scripts/init_project.sh my_app ~/path/to/ai-rules none
```

### Step 2: Configure Project Requirements

```bash
cd my_app
vim project_requirements.md  # or use your preferred editor
```

**Key Sections to Configure**:

#### Project Overview
- What are you building?
- Who are the target users?
- What are the key features?

#### Technical Stack
- **Framework**: Phoenix, Nerves, or Library?
- **Elixir Version**: 1.17.3 recommended
- **Database**: PostgreSQL, MySQL, or none?

#### LLM Configuration
**Planning Phase**:
- **Primary Model**: Claude 3.5 Sonnet (recommended)
- **Fallback**: Claude 3 Opus
- **Local Provider**: Ollama or LM Studio?

**Building Phase**:
- **Primary Model**: DeepSeek Coder 16B (recommended for local)
- **Fallback**: Llama 3.1 70B
- **Local Provider**: Ollama or LM Studio?

**Reviewing Phase**:
- **Primary Model**: Claude 3.5 Sonnet (recommended)
- **Fallback**: Claude 3 Opus

#### Tool Configuration
- **mgrep**: Enable in plan and review modes?
- **Serena**: Enable in build and review modes?

#### Architecture Requirements
- **Design Pattern**: Domain Resource Action (recommended)?
- **OTP Supervision**: One-for-one, one-for-all, dynamic?
- **State Management**: GenServer, Agent, ETS, or none?

#### Testing Strategy
- **Coverage Goal**: 80%+ recommended
- **Property-Based Testing**: Yes or no?
- **E2E Tests**: For critical user journeys?

See `configs/project_requirements.md` template for full structure.

### Step 3: Setup Nix Environment (if using Nix)

```bash
# If you have a custom flake.nix, copy it to project
cp ~/path/to/your/flake.nix .

# Otherwise, use ai-rules template
cp ai-rules/configs/nix_flake_template.nix flake.nix

# Enter Nix development shell
nix develop
```

**What This Does**:
- Provides Elixir, OTP, Erlang, Node.js
- Configures local LLM paths
- Sets up MLX GPU support (M2 Max)
- Ensures reproducible dependencies

### Step 4: Initialize Nix Dependencies

```bash
# Install Elixir dependencies
mix deps.get

# Install Node.js dependencies (for Phoenix assets)
cd assets && npm install && cd ..
```

---

## Multi-Session Setup

### Overview

`ai-rules` supports **multi-session development** with separate OpenCode sessions for:
1. **Plan Session** - Architecture and design
2. **Build Session** - Implementation and coding
3. **Review Session** - Quality assurance (optional)

### Session 1: Plan Session (Terminal 1)

```bash
# Open Terminal 1
cd my_app

# Start OpenCode in plan mode
opencode --config .opencode/opencode.plan.json
```

**What Happens**:
- OpenCode loads **Architect** agent
- **Tools Available**:
  - ✅ mgrep (primary - semantic discovery)
  - ✅ grep (exact pattern matching)
  - ✅ websearch (external patterns)
  - ❌ write (disabled - read-only)
  - ❌ serena_* (disabled - no editing)
- **Model**: Claude 3.5 Sonnet (API) or Llama 3.1 70B (local)

**Example Prompts**:

```text
"Create a Phoenix application with user authentication using Guardian.
Follow Domain Resource Action pattern with proper OTP supervision tree.
Design domains for accounts, sessions, and notifications.
Output detailed architecture plan in project_requirements.md."
```

```text
"Search for existing OTP patterns in similar projects using mgrep.
Find Domain Resource Action examples that I can follow.
Design supervision tree with clear fault boundaries."
```

**Expected Output**:
- File structure (lib/, test/, config/)
- Supervision tree design
- Domain/resource/action breakdown
- Initial `mix.exs` configuration
- Updated `project_requirements.md` with architecture

**When to Exit**:
- When architecture plan is complete
- When `project_requirements.md` is updated
- When file structure plan is documented

### Session 2: Build Session (Terminal 2)

```bash
# Open Terminal 2
cd my_app

# Start OpenCode in build mode
opencode --config .opencode/opencode.build.json
```

**What Happens**:
- OpenCode loads **Orchestrator** agent
- **Tools Available**:
  - ✅ write (primary - create/modify code)
  - ✅ serena_* (primary - semantic search + edit)
  - ✅ grep (exact searches)
  - ⚠️ mgrep (reference only - quick lookups)
  - ✅ bash (run mix commands, tests)
- **Model**: DeepSeek Coder 16B (local - Ollama) or LM Studio Phi-4-mini

**Example Prompts**:

```text
"Implement user authentication feature according to plan in project_requirements.md.
Use /create-feature command for accounts domain, user resource, create action.
Follow TDD - write failing tests first.
Run /full-test before committing changes."
```

```text
"Use Serena to search for existing authentication patterns in codebase.
Edit user registration action to follow Domain Resource Action pattern.
Implement GenServer for session management with proper supervision."
```

**Expected Output**:
- Complete implementation code (lib/)
- ExUnit tests (test/)
- Ecto schemas and migrations (priv/repo/migrations/)
- OTP-compliant modules
- Passing tests

**When to Exit**:
- When feature implementation is complete
- When tests pass
- When code quality checks pass

### Session 3: Review Session (Terminal 3, Optional)

```bash
# Open Terminal 3
cd my_app

# Start OpenCode in review mode
opencode --config .opencode/opencode.review.json
```

**What Happens**:
- OpenCode loads **Reviewer + QA** agents
- **Tools Available**:
  - ❌ write (disabled - analysis only)
  - ✅ mgrep (active - cross-reference)
  - ✅ serena_* (active - edit context)
  - ✅ grep (pattern verification)
  - ✅ bash (quality checks)
- **Model**: Claude 3.5 Sonnet (API) or Llama 3.1 70B (local)

**Example Prompts**:

```text
"Review user authentication implementation.
Use mgrep to cross-reference similar patterns in codebase.
Use Serena to understand edit context.
Check for OTP best practices, N+1 queries, test coverage.
Provide recommendations for improvements."
```

**Expected Output**:
- Code review report with specific issues
- Test coverage analysis
- Recommendations for improvements
- Quality metrics

**When to Exit**:
- When review is complete
- When all issues are addressed or documented

### Session Management Tips

**Context Sharing**:
- Each terminal has independent OpenCode session
- No shared context between sessions
- Share state via files (project_requirements.md, code)

**Mode Transitions**:
1. **Plan → Build**: Read `project_requirements.md` for architecture plan
2. **Build → Review**: Code is ready for review
3. **Review → Plan**: For new features or major refactors

**File Watching**:
- OpenCode monitors file changes in active session
- Use `Ctrl+C` to exit session
- Sessions can be restarted anytime

---

## Development Workflow

### Standard Development Cycle

#### 1. Plan New Feature
```bash
# Terminal 1: Plan session
opencode --config .opencode/opencode.plan.json

# Prompt:
"Plan a user registration feature with email verification.
Design domain boundary for accounts, resource for user, actions for register and verify.
Document plan in project_requirements.md."
```

#### 2. Implement Feature (TDD)
```bash
# Terminal 2: Build session
opencode --config .opencode/opencode.build.json

# Prompt:
"Implement user registration feature using /create-feature.
Write failing tests first, then implement to make tests pass.
Follow Domain Resource Action pattern."
```

#### 3. Review and Iterate
```bash
# Terminal 3: Review session (optional)
opencode --config .opencode/opencode.review.json

# Prompt:
"Review user registration implementation.
Check for N+1 queries, OTP patterns, test coverage.
Provide recommendations."
```

#### 4. Commit Changes
```bash
# In build session or terminal
git add .
git commit -m "feat: implement user registration

- Add accounts domain, user resource
- Implement register and verify actions
- Add comprehensive tests
- All tests passing, coverage 85%"
```

### TDD Workflow with ai-rules

#### Step 1: Red - Write Failing Test
```bash
# In build session, ask AI:
"Write failing test for user registration with valid email and password."
```

**Expected Test**:
```elixir
defmodule Accounts.User.RegisterTest do
  use Accounts.DataCase

  test "registers user with valid attributes" do
    attrs = %{email: "test@example.com", password: "SecurePass123!"}
    assert {:ok, %User{} = user} = Accounts.User.Register.call(attrs)
    assert user.email == "test@example.com"
  end
end
```

#### Step 2: Green - Make Test Pass
```bash
# Ask AI:
"Implement user registration action to make test pass."
```

**Expected Implementation**:
```elixir
defmodule Accounts.User.Register do
  alias Accounts.{User, Repo}

  @spec call(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def call(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end
end
```

#### Step 3: Refactor - Improve Code
```bash
# Ask AI:
"Refactor user registration to add password hashing.
Run /full-test to ensure all tests still pass."
```

**Expected Refactor**:
```elixir
defmodule Accounts.User.Register do
  alias Accounts.{User, Repo}

  @spec call(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
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

### Continuous Integration

#### Running Quality Checks
```bash
# In build session, ask AI:
"Run /full-test to verify code quality."

# Or manually:
mix format
mix credo --strict
mix dialyzer
mix test --cover
```

#### Interpreting Results
- **Format**: Fix all formatting issues
- **Credo**: Address warnings, refactor code smell
- **Dialyzer**: Fix type mismatches
- **Coverage**: Ensure >80% (or project goal)

---

## Common Issues

### Issue 1: mgrep Returns No Results

**Symptom**:
```text
"mgrep: No results found"
```

**Causes**:
- Codebase not indexed
- Query too specific
- Wrong directory

**Solutions**:
```bash
# 1. Index codebase
mgrep watch
# Leave running in background or run before queries

# 2. Use broader natural language
# Bad: "defmodule Accounts.User.Create do"
# Good: "Domain Resource Action create examples"

# 3. Check directory
cd my_app  # Ensure in project root
mgrep "user authentication patterns"

# 4. Use web search for external patterns
mgrep --web "OTP GenServer best practices"
```

### Issue 2: Serena MCP Not Available

**Symptom**:
```text
"Error: MCP server 'serena' not found"
```

**Causes**:
- uv not installed
- opencode_mcp.json not configured
- Serena MCP not starting

**Solutions**:
```bash
# 1. Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh
uv --version

# 2. Test Serena
uvx --from git+https://github.com/oraios/serena serena start-mcp-server --help

# 3. Check opencode_mcp.json
cat .opencode/mcp.json
# Ensure serena entry exists and enabled: true

# 4. Restart OpenCode
opencode --config .opencode/opencode.build.json
```

### Issue 3: Local LLM Slow or Not Responding

**Symptom**:
- Very slow responses from local LLM
- Timeout errors

**Causes**:
- Model too large for hardware
- Not using GPU acceleration
- Ollama/LM Studio not running

**Solutions**:
```bash
# 1. Check Ollama is running
ollama list

# 2. Use smaller model
# Instead of: llama3.1:70b-instruct
# Try: deepseek-coder-v2:16b-instruct

# 3. Enable GPU (if available)
# Ollama uses GPU automatically on M2 Max

# 4. Configure MLX for M2 Max
# See configs/mlx_gpu_config.yml
# Set tensor_parallel: 5 for 5 GPUs
```

### Issue 4: Tests Failing

**Symptom**:
```text
** (Test.X) Test accounts/user/register_test.exs:8: Failure
** (ExUnit) "tests with a tag must pass"
```

**Causes**:
- Implementation doesn't match test expectations
- Test setup incorrect
- Database not migrated

**Solutions**:
```bash
# 1. Run tests with trace output
mix test --trace

# 2. Run specific test file
mix test test/accounts/user/register_test.exs

# 3. Check migrations
mix ecto.migrate

# 4. Review test setup
# Ensure fixtures are loaded correctly

# 5. Ask AI for help
# In build session:
"Tests are failing. Help debug using trace output."
```

### Issue 5: Code Quality Checks Fail

**Symptom**:
```text
mix credo
...
  [W] Module is too long (200+ lines)
  [W] Function has too many arguments (5+ args)
```

**Causes**:
- Code smell or anti-patterns
- Violation of Elixir best practices

**Solutions**:
```bash
# 1. Run Credo with explain
mix credo --explain

# 2. Fix issues one by one
# Ask AI:
"Fix Credo warnings in this file. Refactor following OTP best practices."

# 3. Use suggested fixes
# Credo provides actionable suggestions

# 4. Re-run checks
mix credo --strict
```

### Issue 6: Plan and Build Sessions Out of Sync

**Symptom**:
- Build session implements different architecture than planned
- Plan session missing updates from build

**Causes**:
- Not reading latest `project_requirements.md`
- Sessions not aware of each other's changes

**Solutions**:
```bash
# 1. Always read project_requirements.md in build session
"Read project_requirements.md to get latest plan before implementing."

# 2. Update plan after changes
# In plan session:
"Update architecture plan based on implementation feedback."

# 3. Use git history
git log --oneline  # Review recent commits
git diff HEAD~1 HEAD  # See what changed

# 4. Use comments in files
# Add TODO/FIXME comments for future work
```

---

## Next Steps

### After Project Initialization

1. ✅ **Review ai-rules Documentation**
   - Read `README.md` for overview
   - Read `AGENTS.md` for agent guidelines
   - Review relevant roles and skills

2. ✅ **Configure project_requirements.md**
   - Fill in all required sections
   - Choose LLMs for each phase
   - Enable/disable tools appropriately

3. ✅ **Start Plan Session** (Terminal 1)
   ```bash
   opencode --config .opencode/opencode.plan.json
   ```
   - Ask Architect to design system
   - Get file structure and supervision tree

4. ✅ **Start Build Session** ( Terminal 2)
   ```bash
   opencode --config .opencode/opencode.build.json
   ```
   - Implement according to plan
   - Follow TDD workflow
   - Use Serena for semantic search + edit

5. ✅ **Start Review Session** (Terminal 3, Optional)
   ```bash
   opencode --config .opencode/opencode.review.json
   ```
   - Review code for quality
   - Check OTP best practices
   - Verify test coverage

### For Development

6. 🔄 **Follow Development Cycle**
   - Plan features in plan session
   - Implement in build session (TDD)
   - Review in review session
   - Commit with descriptive messages

7. 📊 **Run Quality Checks**
   - `mix format` - Format code
   - `mix credo` - Code quality
   - `mix dialyzer` - Type checking
   - `mix test --cover` - Coverage

8. 📝 **Update Documentation**
   - Add `@moduledoc` and `@doc` comments
   - Update README.md in project root
   - Document API endpoints

### For Deployment

9. 🚀 **Build Release**
   ```bash
   mix release
   ```

10. 🔧 **Configure Deployment**
    - Set up database
    - Configure environment variables
    - Set up monitoring and logging

---

## Additional Resources

### ai-rules Documentation
- **README.md**: Repository overview
- **AGENTS.md**: Agent guidelines
- **tools/opencode/README.md**: OpenCode integration
- **tools/claude/README.md**: Claude compatibility
- **tools/cursor/README.md**: Cursor usage
- **tools/nix/README.md**: Nix integration
- **roles/README.md**: Role definitions
- **skills/README.md**: Skill documentation

### External Documentation
- **OpenCode Docs**: https://opencode.ai/docs
- **mgrep Docs**: https://github.com/mixedbread-ai/mgrep
- **Serena MCP Docs**: https://github.com/oraios/serena
- **Phoenix Guides**: https://hexdocs.pm/phoenix
- **Elixir Guides**: https://hexdocs.pm/elixir

### Community Support
- **OpenCode Discord**: https://opencode.ai/discord
- **Elixir Forum**: https://elixirforum.com
- **GitHub Issues**: https://github.com/layeddie/ai-rules/issues
---

**Happy coding with ai-rules! 🎉**

For questions or issues, refer to this guide or check relevant documentation in `ai-rules/` folder.
