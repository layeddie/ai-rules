# Claude Integration Guide

This guide explains how to use `.ai_rules` with Claude Code, Claude Desktop, or Cursor (which uses Claude API).

---

## Overview

`.ai_rules` is **compatible with Claude** through the `.claude/` folder structure:

```
.claude/
├── agents/      # Agent definitions (elixir-architect, elixir-tester, etc.)
├── commands/     # Custom commands (/create-feature, /full-test)
└── skills/       # Technical skills (otp-patterns, ecto-query-analysis, etc.)
```

### Key Features

- **Agent Definitions**: Role-based agents for different tasks
- **Custom Commands**: Slash commands for common workflows
- **Technical Skills**: Reusable skill modules
- **Integration**: Works with Claude Code, Claude Desktop, Cursor

---

## Agent Definitions

### When to Use Agents

Agents provide **specialized expertise** for different tasks:

- **elixir-architect**: System design, OTP supervision trees
- **elixir-tester**: ExUnit testing, property-based testing
- **elixir-reviewer**: Code review, OTP best practices
- **ecto-optimizer**: Ecto query optimization, N+1 prevention
- **phoenix-liveview-specialist**: LiveView UI, real-time features

### How to Use Agents

**In Claude Code**:
```text
"Use the elixir-architect agent to design the supervision tree for this feature."
```

**In Claude Desktop**:
```text
"Switch to elixir-reviewer agent to review these changes."
```

**In Cursor**:
```text
"Use elixir-tester agent to write comprehensive tests for this feature."
```

---

## Custom Commands

### Available Commands

`.ai_rules` provides two custom commands:

#### /create-feature

**Purpose**: Create a new Elixir feature following TDD and Domain Resource Action pattern.

**Usage**:
```text
/create-feature <domain> <resource> <actions>
```

**Arguments**:
- `domain`: Domain name (e.g., accounts, billing, blog)
- `resource`: Resource name (e.g., user, subscription, post)
- `actions`: Comma-separated actions (e.g., create,update,delete)

**What This Does**:
1. Creates domain directory structure
2. Creates resource directory under domain
3. Creates action modules for each specified action
4. Creates API module for resource
5. Generates test files with failing tests
6. Creates schema and migration if applicable

**Example**:
```text
/create-feature accounts user create,update,delete
```

Creates:
```
lib/my_app/accounts/
  user/
    create.ex
    update.ex
    delete.ex
    api.ex
test/my_app/accounts/user/
  create_test.exs
  update_test.exs
  delete_test.exs
```

#### /full-test

**Purpose**: Run complete test suite with coverage and quality checks.

**What This Does**:
1. Runs all ExUnit tests
2. Generates test coverage report
3. Checks code formatting
4. Runs Credo for code quality
5. Runs Dialyzer for type checking (if configured)

**Usage**:
```text
/full-test
```

**Expected Output**:
- Test results and coverage percentage
- Formatting errors (if any)
- Credo warnings
- Dialyzer type issues (if configured)

---

## Technical Skills

### Available Skills

Skills are **reusable technical modules** that can be invoked by any agent:

#### otp-patterns
**Purpose**: Implement OTP design patterns including GenServer, Supervisor, and Application behaviors.

**When to Use**:
- Creating new GenServers or Supervisors
- Designing supervision trees
- Implementing process-based features

**Usage**:
```text
"Use the otp-patterns skill to implement a GenServer for this cache feature."
```

#### ecto-query-analysis
**Purpose**: Analyze Ecto queries for N+1 problems, missing preloads, and performance issues.

**When to Use**:
- Reviewing Ecto query code
- Investigating slow database queries
- Optimizing database access patterns

**Usage**:
```text
"Use the ecto-query-analysis skill to check for N+1 queries in this user list."
```

#### test-generation
**Purpose**: Generate comprehensive Elixir tests using ExUnit following TDD principles.

**When to Use**:
- Writing tests for new features
- Creating test strategies
- Implementing property-based tests

**Usage**:
```text
"Use the test-generation skill to write comprehensive tests for this authentication feature."
```

---

## Workflow with Claude

### Single-Session Workflow

If using **Claude Code** (single session), you can still follow a plan/build/review workflow:

#### Planning Phase
```text
"Act as the elixir-architect agent. Design a Phoenix application with user authentication.
Follow Domain Resource Action pattern and OTP best practices.
Output the architecture plan with supervision tree design."
```

#### Implementation Phase
```text
"Act as an Orchestrator. Implement the user authentication feature according to the plan.
Use /create-feature to set up the domain and resource structure.
Follow TDD - write failing tests first.
Use the otp-patterns skill for GenServer implementation."
```

#### Review Phase
```text
"Act as the elixir-reviewer agent. Review the user authentication implementation.
Check for OTP best practices, N+1 queries, and test coverage.
Use the ecto-query-analysis skill to identify performance issues.
Provide specific, actionable recommendations."
```

### Multi-Session Alternative

You can also use **multiple Claude sessions** similar to OpenCode:

```bash
# Terminal 1: Plan session
claude-code

# In Claude Code:
"Act as elixir-architect. Plan the system architecture..."

# Terminal 2: Build session (another Claude Code instance)
claude-code

# In Claude Code:
"Act as Orchestrator. Implement according to plan..."

# Terminal 3: Review session
claude-code

# In Claude Code:
"Act as elixir-reviewer. Review the implementation..."
```

---

## Configuration

### Claude Desktop Configuration

**Claude Desktop Config Location**:
- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Windows**: `%APPDATA%/Claude/claude_desktop_config.json`
- **Linux**: `~/.config/claude/claude_desktop_config.json`

**Add .ai_rules Path**:
```json
{
  "aiRulesPath": "~/projects/2025/.ai_rules"
}
```

**Note**: Claude Desktop automatically loads `.claude/` folder if it exists in your project.

### Cursor Configuration

**Cursor uses `.cursorrules` file** which contains agent rules and system prompts.

**.cursorrules Location**:
- Project root directory
- Parent directory (affects all projects in directory)

**Add .ai_rules Rules**:
See `tools/cursor/.cursorrules` for complete rules file.

---

## Limitations vs OpenCode

### Claude Limitations

- **No Native MCP Support**: Claude has limited MCP support compared to OpenCode
- **Manual Mode Switching**: No built-in multi-session workflow
- **Limited mgrep Integration**: mgrep not natively integrated
- **Manual Tool Management**: Tools need to be configured manually

### OpenCode Advantages

- **Multi-Session Native**: Built-in plan/build/review workflow
- **Full MCP Support**: Serena MCP integration out of the box
- **mgrep Native**: Built-in mgrep integration
- **Mode-Specific Configs**: Separate configs for plan/build/review

---

## Best Practices

### When to Use Claude

**Use Claude When**:
- You prefer Claude's interface
- You're already using Claude Code/Desktop
- You want quick code assistance without complex workflows
- You're working on smaller tasks that don't require multi-session

**Use OpenCode When**:
- You need multi-session workflow
- You want native MCP support (Serena)
- You want mgrep integration
- You're working on larger projects with complex architecture

### Combining Tools

You can use **both Claude and OpenCode**:

1. **Use Claude** for quick code assistance and questions
2. **Use OpenCode** for multi-session workflows
3. **Share the same .ai_rules** folder between both tools
4. **Sync changes via git**

---

## Migration from Claude to OpenCode

If you want to migrate from Claude to OpenCode:

### Step 1: Copy Configuration
```bash
# Copy .claude/ folder to project
cp -r .claude my_project/

# Copy project_requirements.md
cp .ai_rules/configs/project_requirements.md my_project/
```

### Step 2: Create OpenCode Config
```bash
cd my_project

# Create .opencode/ directory
mkdir -p .opencode

# Copy OpenCode configs
cp .ai_rules/tools/opencode/*.json .opencode/
```

### Step 3: Update project_requirements.md
- Adjust LLM settings for OpenCode
- Update tool preferences
- Add mode-specific configurations

### Step 4: Start OpenCode Sessions
```bash
# Terminal 1: Plan
opencode --config .opencode/opencode.plan.json

# Terminal 2: Build
opencode --config .opencode/opencode.build.json
```

---

## Troubleshooting

### Issue: Agents Not Found

**Symptom**:
```text
"Agent not found: elixir-architect"
```

**Solution**:
```bash
# Check .claude/agents/ folder exists
ls -la .claude/agents/

# Verify agent files are present
cat .claude/agents/elixir-architect.md
```

### Issue: Commands Not Available

**Symptom**:
```text
"Command not recognized: /create-feature"
```

**Solution**:
```bash
# Check .claude/commands/ folder
ls -la .claude/commands/

# Verify command files are present
cat .claude/commands/create-feature.md
```

### Issue: Skills Not Found

**Symptom**:
```text
"Skill not found: otp-patterns"
```

**Solution**:
```bash
# Check .claude/skills/ folder
ls -la .claude/skills/

# Verify skill folders are present
cat .claude/skills/otp-patterns/SKILL.md
```

---

## Summary

Claude compatibility with `.ai_rules` provides:

✅ **Role-Based Agents**: Specialized expertise for different tasks
✅ **Custom Commands**: /create-feature, /full-test
✅ **Technical Skills**: Reusable modules (otp-patterns, ecto-query-analysis, test-generation)
✅ **Claude Integration**: Works with Claude Code, Claude Desktop, Cursor

**Limitations**: No native MCP support, manual mode switching, limited mgrep integration

**Recommendation**: Use OpenCode for full-featured multi-session workflows with MCP and mgrep integration. Use Claude for quick assistance or if you prefer Claude's interface.

---

**For detailed information**, see:
- `AGENTS.md` - General agent guidelines
- `PROJECT_INIT.md` - Project initialization
- `../../roles/` - Role definitions
- `../../skills/` - Skill documentation
