# OpenCode Integration Guide

This guide explains how to configure and use OpenCode with `.ai_rules` for Elixir/BEAM development.

---

## Overview

OpenCode is an open-source AI coding agent that supports:
- **Multi-Session Workflow**: Separate plan, build, and review sessions
- **MCP Server Integration**: Native support for Serena MCP
- **Local LLM Support**: Ollama, LM Studio, MLX
- **mgrep Integration**: Native semantic search support
- **Role-Based Agents**: Different agent roles per mode

### Key Features for Elixir/BEAM

- **OTP Pattern Recognition**: Understands supervision trees, GenServer, etc.
- **Domain Resource Action**: Supports DRA pattern
- **TDD Workflow**: Built-in support for test-driven development
- **Code Quality**: Integrates with Credo, Dialyzer
- **Multi-Model Support**: Use different LLMs per session

---

## Installation

### Install OpenCode

```bash
# Install via install script (recommended)
curl -fsSL https://opencode.ai/install | bash

# Or via npm
npm install -g opencode-ai

# Or via Homebrew (macOS)
brew install opencode

# Verify installation
opencode --version
```

### Install Dependencies

#### mgrep (Semantic Search)
```bash
# Install Node.js if needed
brew install node

# Install mgrep
npm install -g @mixedbread/mgrep

# Install for OpenCode
mgrep install-opencode

# Verify installation
mgrep --version
```

#### uv & Serena MCP (Semantic Search + Edit)
```bash
# Install uv (Python package manager)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Test Serena MCP (no installation needed, runs via uvx)
uvx --from git+https://github.com/oraios/serena serena start-mcp-server --help

# Note: Serena is ready to use, no separate installation required
```

#### Local LLMs (Optional but Recommended)

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

## Configuration

### Configuration Files

`.ai_rules` provides 4 OpenCode configuration files:

1. **`opencode.json`** - Base configuration template
2. **`opencode.plan.json`** - Plan mode (read-only, mgrep primary)
3. **`opencode.build.json`** - Build mode (full access, Serena primary)
4. **`opencode.review.json`** - Review mode (analysis, both tools)
5. **`opencode_mcp.json`** - MCP server configuration (Serena)

### Using Configuration Files

When initializing a project with `.ai_rules`, these configs are copied to `.opencode/`:

```bash
# After init_project.sh, configuration is ready
cd my_app
ls -la .opencode/

# Output:
# opencode.json
# opencode_mcp.json
```

**To start OpenCode with specific mode**:

```bash
# Plan session
opencode --config .opencode/opencode.plan.json

# Build session
opencode --config .opencode/opencode.build.json

# Review session
opencode --config .opencode/opencode.review.json
```

---

## Multi-Session Workflow

### Overview

OpenCode supports **multi-session development** with separate configurations for each phase:

```
┌─────────────────────────────────────────────────────────────────┐
│                   Terminal 1 (Plan Session)                 │
│  opencode --config .opencode/opencode.plan.json              │
│  ├── Agent: Architect                                      │
│  ├── Tools: mgrep (primary), grep, websearch              │
│  ├── Model: Claude 3.5 Sonnet (API)                     │
│  └── Output: project_requirements.md, file structure plan  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
                    (plan written to files)
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                   Terminal 2 (Build Session)                  │
│  opencode --config .opencode/opencode.build.json             │
│  ├── Agent: Orchestrator                                   │
│  ├── Tools: Serena (primary), grep, write                  │
│  ├── Model: DeepSeek Coder 16B (Ollama - local)         │
│  └── Output: Implementation code, tests                     │
└─────────────────────────────────────────────────────────────────┘
                              ↓
                  (continuous build cycle)
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                   Terminal 3 (Review Session)                  │
│  opencode --config .opencode/opencode.review.json             │
│  ├── Agent: Reviewer/QA                                    │
│  ├── Tools: mgrep, Serena (both active)                    │
│  ├── Model: Claude 3.5 Sonnet (API)                       │
│  └── Output: Code review, test reports                      │
└─────────────────────────────────────────────────────────────────┘
```

### Session 1: Plan Session

**Purpose**: Architecture and design

**Configuration**: `.opencode/opencode.plan.json`

**Agent**: Architect

**Tools**:
- ✅ **mgrep**: Primary - Semantic discovery of existing patterns
- ✅ **grep**: Exact pattern matching
- ✅ **websearch**: External best practices and documentation
- ❌ **write**: Disabled - Read-only planning
- ❌ **serena_***: Disabled - No editing needed

**Model Selection**:
- **Primary**: Claude 3.5 Sonnet (API) - Strong architectural reasoning
- **Fallback**: Claude 3 Opus
- **Local**: Llama 3.1 70B-instruct (Ollama/MLX)

**Start Plan Session**:
```bash
# Open Terminal 1
cd my_app

# Start OpenCode in plan mode
opencode --config .opencode/opencode.plan.json

# Example prompt:
"Create a Phoenix application with user authentication using Guardian.
Follow Domain Resource Action pattern with proper OTP supervision tree.
Design domains for accounts, sessions, and notifications.
Output detailed architecture plan in project_requirements.md."
```

**Expected Output**:
- File structure (lib/, test/, config/)
- Supervision tree design
- Domain/resource/action breakdown
- Initial `mix.exs` configuration
- Updated `project_requirements.md` with architecture section

**When to Exit**:
- When architecture plan is complete
- When `project_requirements.md` is updated
- When file structure plan is documented

### Session 2: Build Session

**Purpose**: Implementation and coding

**Configuration**: `.opencode/opencode.build.json`

**Agent**: Orchestrator

**Tools**:
- ✅ **write**: Primary - Create and modify code
- ✅ **serena_*`**: Primary - Semantic search + editing
- ✅ **grep**: Fast exact searches
- ⚠️ **mgrep**: Reference only - Quick lookups when needed
- ✅ **bash**: Run mix commands, tests

**Model Selection**:
- **Primary**: DeepSeek Coder 16B-instruct (Ollama) - Fast, good at code
- **Fallback**: Llama 3.1 70B-instruct
- **Local**: LM Studio Phi-4-mini for small edits

**Start Build Session**:
```bash
# Open Terminal 2
cd my_app

# Start OpenCode in build mode
opencode --config .opencode/opencode.build.json

# Example prompt:
"Implement user authentication feature according to plan in project_requirements.md.
Use /create-feature command for accounts domain, user resource, create action.
Follow TDD - write failing tests first.
Run /full-test before committing changes."
```

**Expected Output**:
- Complete implementation code (lib/, test/)
- ExUnit tests (passing)
- Ecto schemas and migrations (priv/repo/migrations/)
- OTP-compliant modules

**When to Exit**:
- When feature implementation is complete
- When tests pass
- When code quality checks pass

### Session 3: Review Session

**Purpose**: Quality assurance and code review

**Configuration**: `.opencode/opencode.review.json`

**Agent**: Reviewer + QA

**Tools**:
- ✅ **mgrep**: Active - Cross-reference analysis
- ✅ **serena_*`**: Active - Edit context understanding
- ✅ **grep**: Quick pattern verification
- ❌ **write**: Disabled - Analysis only
- ✅ **bash**: Run quality checks (Credo, Dialyzer, coverage)

**Model Selection**:
- **Primary**: Claude 3.5 Sonnet (API) - Strong analysis
- **Fallback**: Claude 3 Opus
- **Local**: Llama 3.1 70B-instruct

**Start Review Session**:
```bash
# Open Terminal 3
cd my_app
opencode --config .opencode/opencode.review.json

# Example prompt:
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

---

## Tool Usage

### mgrep (Semantic Search)

**When to Use**:
- **Plan Mode**: Discover existing patterns, find similar implementations
- **Build Mode**: Quick reference when stuck (use sparingly)
- **Review Mode**: Cross-reference code for consistency

**Best Practices**:
- Use natural language queries: `"where do we handle user authentication?"`
- Use web search for external patterns: `mgrep --web "OTP GenServer patterns"`
- Limit results: `-m 20` for manageable output
- Show content: `-c` to see code snippets

**Example Queries**:
```bash
# Plan mode: Discover patterns
mgrep "Domain Resource Action examples in codebase"
mgrep -m 10 "GenServer callback patterns"
mgrep --web "Ash authentication best practices"

# Build mode: Quick reference
mgrep "where is user registration action?"
mgrep "how do we handle sessions?"

# Review mode: Cross-reference
mgrep "similar authentication implementations"
mgrep "N+1 query patterns in codebase"
```

**Integration**:
- Native integration with OpenCode via `mgrep install-opencode`
- Configured as bash tool (can be called by OpenCode)
- Complements OpenCode's grep (ripgrep) for exact searches
- Works with existing OpenCode infrastructure

### Hybrid Search Strategy: ripgrep + mgrep

OpenCode supports a hybrid search strategy that combines both tools:

| Query Type | Tool | Example | Why |
|------------|-------|----------|------|
| **Exact symbol** | ripgrep (OpenCode grep) | "find UserService" | Instant exact match |
| **Regex pattern** | ripgrep (OpenCode grep) | "def handle_*" | Regex capabilities |
| **Concept discovery** | mgrep (via bash) | "where do we handle errors?" | Semantic understanding |
| **Pattern exploration** | mgrep (via bash) | "how do we structure supervisors?" | Relevance ranking |

**Quick Reference**:
```bash
# Exact searches (ripgrep)
"Find UserService module"
→ OpenCode grep (ripgrep) automatically

# Semantic searches (mgrep)
"Where do we handle authentication?"
→ OpenCode LLM uses mgrep via bash automatically
```

**Benefits**:
- **56% average token reduction** vs grep-only approach
- **Natural language queries** via mgrep
- **Instant exact searches** via ripgrep
- **Automatic tool selection** by LLM
- **Free tier available** for mgrep

**Setup**:
```bash
# One-time setup
npm install -g @mixedbread/mgrep
mgrep install-opencode

# After setup, LLM chooses automatically
# No configuration needed for most users
```

**Documentation**:
- [Hybrid Strategy Guide](../docs/mixed-search-strategy.md) - Detailed guide with examples
- [AGENTS.md](../AGENTS.md) - Agent guidelines with tool selection
- [GitHub PR Summary](../docs/github_pr_mgrep_summary.md) - Implementation experience

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
- Starts automatically when OpenCode loads MCP config

**Example Usage**:
```bash
# Build mode: Use Serena for search + edit
"Use Serena to find existing user registration patterns.
Edit to follow Domain Resource Action pattern.
Implement GenServer for session management."

# Review mode: Use Serena for context
"Use Serena to understand edit context for code review.
Analyze N+1 query issues in user actions."
```

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

# Find error patterns
grep -r "has already been taken" lib/
```

---

## Model Configuration

### Local LLMs

#### Ollama
```json
{
  "localModels": {
    "ollama": {
      "enabled": true,
      "baseURL": "http://localhost:11434",
      "models": {
        "plan": "llama3.1:70b-instruct-q8_0",
        "build": "deepseek-coder-v2:16b-instruct",
        "review": "llama3.1:70b-instruct-q8_0"
      }
    }
  }
}
```

#### LM Studio
```json
{
  "localModels": {
    "lmstudio": {
      "enabled": true,
      "baseURL": "http://localhost:1234/v1",
      "models": {
        "plan": "phi-4-mini-instruct",
        "build": "phi-4-mini-instruct",
        "review": "phi-4-mini-instruct"
      }
    }
  }
}
```

#### MLX (Apple Silicon)
```yaml
# configs/mlx_gpu_config.yml
gpu:
  tensor_parallel: 5
  max_gpus: 5
  vram_limit: 45

models:
  llama3.1_70b:
    path: "mlx-community/Llama-3.1-70B-Instruct-4bit"
    quantization:
      enabled: true
      bits: 4
```

### API LLMs

#### Anthropic (Claude)
```json
{
  "model": {
    "provider": "anthropic",
    "apiKey": "${ANTHROPIC_API_KEY}",
    "model": "claude-3-5-sonnet-20241022"
  }
}
```

#### OpenCode Zen
```json
{
  "model": {
    "provider": "zen",
    "enabled": true
  }
}
```

---

## Common Issues

### Issue: OpenCode Not Found

**Symptom**:
```bash
command not found: opencode
```

**Solution**:
```bash
# Install OpenCode
curl -fsSL https://opencode.ai/install | bash

# Verify installation
opencode --version
```

### Issue: mgrep Not Found

**Symptom**:
```bash
mgrep: command not found
```

**Solution**:
```bash
# Install Node.js if needed
brew install node

# Install mgrep
npm install -g @mixedbread/mgrep

# Install for OpenCode
mgrep install-opencode

# Verify installation
mgrep --version
```

### Issue: Serena MCP Connection Failed

**Symptom**:
```text
Error: MCP server 'serena' not found or failed to start
```

**Solution**:
```bash
# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Test Serena
uvx --from git+https://github.com/oraios/serena serena start-mcp-server --help

# Check opencode_mcp.json
cat .opencode/mcp.json

# Restart OpenCode
opencode --config .opencode/opencode.build.json
```

### Issue: Local LLM Slow

**Symptom**:
- Very slow responses from local LLM
- Timeout errors

**Solution**:
```bash
# Use smaller model
# Instead of: llama3.1:70b-instruct
# Try: deepseek-coder-v2:16b-instruct

# Enable GPU (M2 Max)
# Ollama uses GPU automatically

# Configure MLX
# See configs/mlx_gpu_config.yml
```

### Issue: Configuration Not Applied

**Symptom**:
- OpenCode not using `.ai_rules` configuration
- Tools not available as expected

**Solution**:
```bash
# Verify config file syntax
opencode validate .opencode/config.json

# Check config file path
ls -la .opencode/

# Restart OpenCode after config changes
opencode --config .opencode/opencode.build.json

# Check project_requirements.md for LLM settings
cat project_requirements.md | grep -A 5 "LLM Configuration"
```

---

## Best Practices

### Plan Session Best Practices

1. **Use mgrep for Discovery**
   ```bash
   # Good
   mgrep "OTP supervisor patterns in codebase"

   # Bad
   grep -r "defmodule" lib/
   ```

2. **Leverage Web Search**
   ```bash
   # Find best practices
   mgrep --web "Phoenix LiveView performance tips"
   ```

3. **Read Existing Code**
   - Always check project for existing patterns
   - Don't duplicate work
   - Follow project conventions

4. **Document Architecture**
   - Update `project_requirements.md`
   - Document file structure
   - Explain design decisions

### Build Session Best Practices

1. **Follow TDD**
   ```bash
   # Write failing test first
   # Then implement
   # Refactor with confidence
   ```

2. **Use Serena for Semantic Search**
   ```bash
   # Find similar implementations
   "Use Serena to search for user registration patterns"
   ```

3. **Run Quality Checks**
   ```bash
   mix format
   mix credo --strict
   mix dialyzer
   mix test --cover
   ```

4. **Reference mgrep Sparingly**
   - Use for quick lookups only
   - Don't over-rely on it in build mode
   - Prefer Serena for semantic understanding

### Review Session Best Practices

1. **Use Both Tools**
   - mgrep for cross-referencing
   - Serena for edit context
   - grep for pattern verification

2. **Provide Specific Feedback**
   - Don't nitpick style
   - Explain "why" behind suggestions
   - Give actionable recommendations

3. **Check Test Coverage**
   - Verify >80% (or project goal)
   - Check for untested edge cases
   - Review test quality

4. **Review OTP Patterns**
   - Check supervision strategies
   - Verify named processes
   - Ensure fault boundaries

---

## Summary

OpenCode with `.ai_rules` provides:

✅ **Multi-session workflow** - Separate plan, build, review sessions
✅ **Optimized for Elixir/BEAM** - OTP patterns, DRA, TDD
✅ **Tool integration** - mgrep, Serena MCP native support
✅ **Flexible LLM support** - Local (Ollama, LM Studio, MLX) + API
✅ **Role-based agents** - Architect, Orchestrator, Reviewer per mode
✅ **Subscription-free** - All tools open-source and free

**For detailed usage**, see:
- `PROJECT_INIT.md` - Project initialization
- `AGENTS.md` - Agent guidelines
- `../../roles/` - Role definitions
- `../../skills/` - Technical skills

**Happy coding with OpenCode and .ai_rules! 🎉**
