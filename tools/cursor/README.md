# Cursor Integration Guide

This guide explains how to use `.ai_rules` with Cursor (VS Code-based AI agent).

---

## Overview

Cursor is a VS Code extension that provides AI-powered coding assistance. `.ai_rules` provides guidelines and rules that Cursor can follow.

### Key Features

- **Agent-Based Prompting**: Role-specific guidelines from `.ai_rules`
- **Custom Commands**: Slash commands for common workflows
- **Elixir/BEAM Focused**: Optimized for OTP patterns, Domain Resource Action
- **Integration**: Works with Cursor's AI capabilities

---

## Configuration

### .cursorrules File

Cursor uses a **`.cursorrules` file** in your project root to define agent behavior and rules.

**Location**:
```
my_app/
  ├── .cursorrules    # Cursor rules file
  └── .ai_rules/    # Symlink to .ai_rules repository
```

**Content**: See `.cursorrules` file in this directory for complete rules configuration.

### Cursor Settings

Cursor can be configured via VS Code settings:

```json
// settings.json
{
  "cursor.ai.enabled": true,
  "cursor.rules.enabled": true,
  "cursor.rules.path": ".cursorrules"
}
```

---

## Using .ai_rules with Cursor

### Workflow

Unlike OpenCode's **multi-session** approach, Cursor is a **single-session** tool. To simulate plan/build/review workflow:

#### Planning Phase
```text
Act as an elixir-architect agent. Read .ai_rules/roles/architect.md for guidance.
Design a Phoenix application with user authentication following Domain Resource Action pattern.
Create a detailed architecture plan with supervision tree design.
Output to project_requirements.md or a new plan.md file.
```

#### Implementation Phase
```text
Act as an orchestrator agent. Read .ai_rules/roles/orchestrator.md for guidance.
Implement the user authentication feature according to the architecture plan.
Follow TDD - write failing tests first.
Use Domain Resource Action pattern with proper OTP supervision.
```

#### Review Phase
```text
Act as an elixir-reviewer agent. Read .ai_rules/roles/reviewer.md for guidance.
Review the user authentication implementation.
Check for OTP best practices, Domain Resource Action adherence, and code quality.
Provide specific, actionable feedback.
```

---

## .cursorrules Structure

The `.cursorrules` file provides:

### Agent Roles

Defines how Cursor should behave in different contexts:

```text
# Agent Roles

## Architect
Act as an expert Elixir/BEAM architect specializing in system design.
Focus on OTP supervision trees, domain boundaries, and fault tolerance.
Reference .ai_rules/roles/architect.md for detailed guidance.

## Orchestrator
Act as an Elixir/BEAM implementation coordinator.
Focus on TDD, Domain Resource Action pattern, and code quality.
Reference .ai_rules/roles/orchestrator.md for detailed guidance.

## Reviewer
Act as an Elixir/BEAM code review specialist.
Focus on OTP best practices, code quality, and specific feedback.
Reference .ai_rules/roles/reviewer.md for detailed guidance.

## QA
Act as a quality assurance specialist.
Focus on testing strategies, coverage analysis, and edge cases.
Reference .ai_rules/roles/qa.md for detailed guidance.
```

### Tool Usage

Defines how Cursor should approach codebase tasks:

```text
# Tool Usage

## Code Search
When searching for patterns, use semantic queries:
- "Where do we handle user authentication?"
- "Find GenServer implementations with similar patterns"

Use mgrep if available, otherwise use VS Code search.

## Code Writing
When writing Elixir code:
- Follow Domain Resource Action pattern
- Use pattern matching instead of conditionals
- Leverage pipe operator for transformations
- Add @moduledoc and @doc comments

## Code Review
When reviewing code:
- Check OTP patterns and supervision
- Verify Domain Resource Action adherence
- Look for N+1 query problems
- Ensure tests are comprehensive
```

### Elixir/BEAM Patterns

Defines specific patterns for Cursor to follow:

```text
# Elixir/BEAM Patterns

## GenServer
Use GenServer for stateful processes with client/server separation:

```elixir
defmodule Cache.Worker do
  use GenServer

  # Client API
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def get(key), do: GenServer.call(__MODULE__, {:get, key})
  def put(key, value), do: GenServer.cast(__MODULE__, {:put, key, value})

  # Server Callbacks
  @impl true
  def init(opts), do: {:ok, %{cache: %{}}}

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

## Supervision
Use named processes and clear restart strategies:

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      MyApp.Repo,
      {Registry, keys: :unique, name: MyApp.Registry},
      {MyApp.Accounts.Supervisor, []},
      MyAppWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

## Domain Resource Action
Organize business logic with Domain > Resource > Action:

```elixir
# Domain: accounts
# Resource: user
# Action: create
defmodule Accounts.User.Create do
  @spec call(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def call(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end
end
```
```

---

## Workflow Simulations

### Planning Session

**Context**: Starting a new feature

```text
I need to add user email verification to the Phoenix application.

Plan the implementation following Domain Resource Action pattern.
Act as an architect agent from .ai_rules.
Design:
- Domain boundary for accounts/verification
- Resource: email_verification
- Actions: send, verify, resend
- OTP processes for background email sending
- Database schema and migrations

Document the plan in project_requirements.md or create a verification-plan.md file.
```

**Expected Output**:
- Domain/resource/action structure
- Supervision tree design
- File organization plan
- Dependencies needed

### Implementation Session

**Context**: Implementing planned feature

```text
I'm implementing the email verification feature according to the plan.

Act as an orchestrator agent from .ai_rules.
Follow TDD:
1. Write failing test for send action
2. Implement send action to pass test
3. Write failing test for verify action
4. Implement verify action to pass test
5. Refactor code with confidence

Use Domain Resource Action pattern:
- lib/my_app/accounts/verification/email_verification.ex
- lib/my_app/accounts/verification/send.ex
- lib/my_app/accounts/verification/verify.ex

Add appropriate tests:
- test/my_app/accounts/verification/send_test.exs
- test/my_app/accounts/verification/verify_test.exs
```

### Review Session

**Context**: Reviewing implementation

```text
Review the email verification implementation.

Act as a reviewer agent from .ai_rules.
Check:
- OTP patterns (GenServer for email sending?)
- Domain Resource Action adherence?
- N+1 queries in user lookups?
- Test coverage for verification actions?
- Code quality (formatting, Credo issues)?

Provide specific feedback:
- GenServer callback separation looks good
- Add missing index on email_verification.verified_at
- Consider using Task.async for email sending instead of GenServer
- Tests are comprehensive, coverage looks good
```

---

## Limitations vs OpenCode

### Cursor Limitations

- **Single Session**: No built-in multi-session workflow (simulate via prompts)
- **No Native MCP**: Limited MCP support compared to OpenCode
- **No Native mgrep**: mgrep not integrated natively (use external)
- **Manual Mode Switching**: Simulate modes via agent role prompts

### OpenCode Advantages

- **Multi-Session Native**: Built-in plan/build/review workflow
- **Full MCP Support**: Serena MCP integration out of the box
- **mgrep Native**: Built-in mgrep integration
- **Mode-Specific Configs**: Separate configurations for each mode

---

## Best Practices

### When to Use Cursor

**Use Cursor When**:
- You prefer VS Code interface
- You're already using Cursor
- You want quick code assistance without complex workflows
- You're working on smaller tasks

**Use OpenCode When**:
- You need multi-session workflow
- You want native MCP support (Serena)
- You're doing complex architecture work
- You want mgrep integration

### Using Both Tools

You can use **Cursor and OpenCode together**:

1. **Use Cursor** for quick code assistance and questions
2. **Use OpenCode** for multi-session workflows (plan/build/review)
3. **Share .ai_rules folder** between both tools
4. **Sync changes via git**

---

## Migration from Cursor to OpenCode

If you want to migrate from Cursor to OpenCode:

### Step 1: Copy .ai_rules
```bash
# Ensure .ai_rules is linked
cd my_app
ln -s ~/projects/2025/.ai_rules .ai_rules
```

### Step 2: Create OpenCode Config
```bash
# Copy OpenCode configurations
mkdir -p .opencode
cp .ai_rules/tools/opencode/*.json .opencode/
```

### Step 3: Start OpenCode Sessions
```bash
# Terminal 1: Plan
opencode --config .opencode/opencode.plan.json

# Terminal 2: Build
opencode --config .opencode/opencode.build.json
```

---

## Troubleshooting

### Issue: .cursorrules Not Loaded

**Symptom**: Cursor not following rules in `.cursorrules` file

**Solutions**:
1. Check file location (should be in project root)
2. Restart Cursor after changes
3. Check Cursor settings for rules path
4. Verify file syntax (valid markdown/format)

### Issue: Agent Behavior Not As Expected

**Symptom**: Cursor not acting as architect/orchestrator/reviewer

**Solutions**:
1. Explicitly specify agent role in prompt
2. Reference relevant .ai_rules/roles/ file
3. Be specific about expected behavior
4. Restart Cursor session

### Issue: Elixir/BEAM Patterns Not Applied

**Symptom**: Code doesn't follow OTP or DRA patterns

**Solutions**:
1. Explicitly request pattern: "Use Domain Resource Action pattern"
2. Reference specific skill: "Use otp-patterns skill"
3. Provide examples of expected pattern
4. Review .cursorrules for pattern definitions

---

## Summary

Cursor with `.ai_rules` provides:

✅ **Agent Roles**: Architect, Orchestrator, Reviewer, QA
✅ **Elixir/BEAM Patterns**: GenServer, Supervision, DRA
✅ **Workflow Simulation**: Can simulate plan/build/review via prompts
✅ **Integration**: Works with VS Code ecosystem

**Limitations**: No native multi-session, limited MCP, no native mgrep

**Recommendation**: Use OpenCode for full-featured multi-session workflows with MCP and mgrep integration. Use Cursor for quick VS Code-based assistance or if you prefer Cursor's interface.

---

**For detailed information**, see:
- `AGENTS.md` - General agent guidelines
- `PROJECT_INIT.md` - Project initialization
- `../roles/` - Role definitions
- `../skills/` - Skill documentation
