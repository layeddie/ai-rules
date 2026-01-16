# Test Project for Elixir-Native Tools Integration

**Purpose**: Demonstrate integration of anubis-mcp, jido_ai, swarm_ex, codicil, and probe

## Project Structure

```
test_project/
├── mix.exs
├── config/
│   ├── config.exs
│   └── dev.exs
├── lib/
│   └── test_project/
│       ├── application.ex
│       ├── mcp/
│       │   └── custom_server.ex
│       └── agents/
│           └── coordinator.ex
└── test/
    └── integration_test.exs
```

## Features Demonstrated

### 1. Anubis MCP - Custom MCP Server
- Custom MCP server with Ecto query tools
- Phoenix integration for HTTP/SSE transport

### 2. Jido AI - Agent Framework
- Multi-agent coordination
- Chain-of-Thought reasoning
- Multi-provider LLM support

### 3. Swarm Ex - Agent Orchestration
- Lightweight agent coordination
- Telemetry integration
- Testable design

### 4. Codicil - Elixir Semantic Search
- Compiler-level code indexing
- Semantic function search
- Dependency analysis

### 5. Probe - AST-Aware Search (Backup)
- Multi-language code search
- AST pattern matching
- Token-aware results

## Setup Instructions

```bash
# 1. Clone test project
cd test_project

# 2. Install dependencies
mix deps.get

# 3. Configure environment variables
export ANTHROPIC_API_KEY=your_key
export OPENAI_API_KEY=your_key
export CODICIL_LLM_PROVIDER=openai

# 4. Initialize Codicil database
mix codicil.setup

# 5. Run tests
mix test

# 6. Start MCP server (optional)
mix run --eval "TestProject.MCPServer.start_link()"
```

## Testing

```bash
# Run integration tests
mix test

# Validate tools installation
cd ../
bash scripts/validate_new_tools.sh

# Run Codicil indexing
cd test_project
mix compile
```

## MCP Server Testing

### With Claude Desktop

Add to `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "test_project": {
      "command": ["mix", "run", "-e", "TestProject.MCPServer.start_link()"],
      "cwd": "/path/to/test_project"
    }
  }
}
```

### With OpenCode

Add to `.opencode/opencode_mcp.json`:

```json
{
  "mcp": {
    "test_project_mcp": {
      "type": "local",
      "command": ["mix", "run", "-e", "TestProject.MCPServer.start_link()"],
      "environment": {
        "MIX_ENV": "dev"
      }
    }
  }
}
```

## Examples

### Example 1: Semantic Search with Codicil

```bash
# Search for similar functions
mix run -e "TestProject.Search.find_similar('user authentication')"

# Output:
# - Similar functions from Codicil
# - Similarity scores
# - Function locations
```

### Example 2: Multi-Agent Coordination

```bash
# Run multi-agent task
mix run -e "TestProject.Coordinator.run_task('create user feature')"

# Output:
# - Jido AI Tree-of-Thoughts planning
# - Swarm Ex agent coordination
# - Task delegation results
```

### Example 3: MCP Server Usage

```bash
# Start MCP server
mix run --eval "TestProject.MCPServer.start_link()"

# Test MCP tools (via Claude Desktop or OpenCode)
# - execute_query: Run Ecto queries
# - list_dependencies: Get module dependencies
# - find_similar: Semantic function search
```

## Documentation

- See `docs/tool_combination_examples.md` for comprehensive tool combinations
- See individual SKILL.md files for tool-specific usage:
  - `skills/anubis-mcp/SKILL.md`
  - `skills/jido_ai/SKILL.md`
  - `skills/swarm-ex/SKILL.md`
  - `skills/codicil/SKILL.md`
  - `skills/probe/SKILL.md`

## Troubleshooting

If issues occur:

1. Check dependencies: `mix deps.check`
2. Verify environment variables: `env | grep API_KEY`
3. Validate tool installation: `bash ../scripts/validate_new_tools.sh`
4. Check Codicil database: `ls -la priv/codicil/`
5. Review logs: `tail -f log/test.log`

## Resources

- ai-rules AGENTS.md: Overall agent guidelines
- tools/NEW_TOOLS_GUIDE.md: Comprehensive tool overview
- tools/opencode/opencode_mcp.json: MCP configuration

---

**Last Updated**: January 16, 2026
