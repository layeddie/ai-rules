# New Tools Integration Guide

**Status**: 🚧 In Progress  
**Date**: January 16, 2026  
**Purpose**: Comprehensive guide for integrating new Elixir-native tools into ai-rules

---

## Overview

This guide integrates 5 new Elixir-native tools into the ai-rules ecosystem, replacing the Arcana framework (removed due to domain mismatch).

### Tool Comparison Matrix

| Tool | Source | Purpose | Type | Stars | License |
|-------|---------|---------|------|-------|----------|
| **anubis-mcp** | zoedsoupe/anubis-mcp | Elixir MCP SDK | SDK | 20 forks upstream | LGPL v3 |
| **jido_ai** | agentjido/jido_ai | Agent framework + LLM | Framework | 0 stars (your fork) | Apache 2.0 |
| **swarm_ex** | nrrso/swarm_ex | Agent orchestration | Library | 83 stars, 8 forks | Apache 2.0 |
| **codicil** | E-xyza/codicil | Elixir semantic search | Library | 41 stars, 2 forks | MIT |
| **Probe** | buger/probe | AST-aware search (backup) | Tool | - | Apache 2.0 |

### Key Decision Points

**Arcana**: ❌ Removed (domain mismatch: data science vs Elixir development)  
**Anubis MCP**: ⚠️ Note: Uses LGPL v3 (copyleft license)  
**Jido AI**: Note: Your fork has zero stars (consider using upstream)  
**Swarm Ex**: ✅ Recommended (lightweight, proven adoption)  
**Codicil**: ✅ Recommended (Elixir-native, deep code understanding)  
**Probe**: ✅ Recommended (backup for mgrep, multi-language support)

---

## Tool 1: Anubis MCP (Elixir MCP SDK)

### What It Is

Complete Elixir SDK for Model Context Protocol (MCP), providing both client and server implementations with Elixir's native concurrency and fault tolerance.

### When to Use

**Best For**:
- Building custom Elixir MCP servers
- Phoenix integration (HTTP/SSE transport)
- Domain-specific tools (Ecto analyzer, Phoenix LiveView inspector)
- Replacing Hermes with your fork (full customization control)

**Avoid For**:
- Quick prototyping (use Hermes or Codicil's pre-built tools)
- Cross-language MCP servers (use Serena)

### Key Capabilities

✅ **Complete client + server implementation**
✅ **Phoenix integration** (HTTP/SSE transport via Plug)
✅ **Streamable HTTP support**
✅ **Tool registration** with input schemas
✅ **BEAM supervision** (built-in supervision trees)
✅ **Production-ready** (error handling, telemetry)

### Quick Start

```elixir
# mix.exs
{:anubis_mcp, "~> 0.17.0"}
```

```elixir
# Server definition
defmodule MyApp.MCPServer do
  use Anubis.Server,
    name: "My Server",
    version: "1.0.0",
    capabilities: [:tools]

  @impl true
  def init(_client_info, frame) do
    {:ok, frame
      |> assign(counter: 0)
      |> register_tool("my_tool",
        input_schema: %{
          query: {:required, :string, description: "Search query"}
        },
        annotations: %{read_only: true},
        description: "Search codebase")
  end

  @impl true
  def handle_tool("my_tool", %{query: query}, frame) do
    {:reply, search_results(query), assign(frame, counter: frame.assigns.counter + 1)}
  end
end

# Phoenix router
forward "/mcp", Anubis.Server.Transport.StreamableHTTP.Plug, server: MyApp.MCPServer
```

### Integration with ai-rules

**Plan Mode**: Use anubis-mcp for custom MCP server development during architecture planning

**Build Mode**: Build domain-specific Elixir MCP servers for ai-rules workflows (e.g., Ecto query analyzer)

**Review Mode**: Verify MCP server implementations follow OTP best practices

### Resources

- HexDocs: https://hexdocs.pm/anubis_mcp
- Upstream: https://github.com/zoedsoupe/anubis-mcp
- Your fork: https://github.com/layeddie/anubis-mcp

### License Note

⚠️ **LGPL v3 (Copyleft)**: 
- Requires derivative works to be LGPL v3
- May not be suitable for commercial projects
- Consider using upstream zoedsoupe/anubis-mcp or building your own SDK under MIT/Apache 2.0

---

## Tool 2: Jido AI (Agent Framework + LLM Integration)

### What It Is

Comprehensive Elixir framework for building sophisticated AI agents and workflows with advanced LLM capabilities and reasoning strategies.

### When to Use

**Best For**:
- Multi-agent orchestration (coordinate multiple specialized agents)
- Advanced reasoning workflows (CoT, ReAct, Tree-of-Thoughts, GEPA)
- Multi-provider LLM access (57+ providers)
- Complex problem-solving with stateful conversations
- Local LLM support (Ollama, LM Studio)

**Avoid For**:
- Simple chatbots (use jido_ai's advanced features)
- Single-agent workflows (leverage orchestration)
- API-only LLMs (use jido_ai's provider abstraction)

### Key Capabilities

✅ **57+ LLM providers** (OpenAI, Anthropic, Google, Mistral, local)
✅ **Advanced reasoning strategies**:
  - Chain of Thought (+8-15% accuracy)
  - ReAct (+27% accuracy)
  - Self-Consistency (+17.9% accuracy)
  - Tree of Thoughts (+74% accuracy)
  - GEPA (+10-19% accuracy)
✅ **Structured prompts** (EEx + Liquid templates)
✅ **Tool integration** (function calling with schema conversion)
✅ **Conversation management** (stateful, ETS storage)
✅ **Context window management** (token counting, truncation)

### Quick Start

```elixir
# mix.exs
{:jido_ai, "~> 0.5.3"}
```

```elixir
alias Jido.AI.{Model, Prompt}
alias Jido.AI.Actions.ReqLlm.ChatCompletion

# Create model
{:ok, model} = Model.from({:anthropic, [model: "claude-3-5-sonnet"]})

# Create prompt
prompt = Prompt.new(:user, "What is the capital of France?")

# Get response
{:ok, result} = ChatCompletion.run(%{model: model, prompt: prompt}, %{})
IO.puts(result.content)
```

### Integration with ai-rules

**Plan Mode**: Use jido_ai agents for multi-agent exploration of codebase architecture

**Build Mode**: Use jido_ai reasoning strategies for complex implementation problems

**Review Mode**: Validate reasoning quality and consistency across agent workflows

### Resources

- HexDocs: https://hexdocs.pm/jido_ai
- Upstream: https://github.com/agentjido/jido_ai
- Your fork: https://github.com/layeddie/jido_ai

### Recommendation

⚠️ **Consider using upstream agentjido/jido_ai** instead of your fork:
- Upstream has proven adoption
- Your fork has zero stars
- Upstream likely more actively maintained

---

## Tool 3: Swarm Ex (Agent Orchestration)

### What It Is

Lightweight, controllable, and testable AI agent orchestration in Elixir. Provides primitives for creating and coordinating networks of AI agents, leveraging Elixir's native concurrency and fault tolerance.

### When to Use

**Best For**:
- Lightweight agent coordination
- Multi-agent task delegation
- Testable agent workflows
- Built-in telemetry and observability

**Avoid For**:
- Heavy agent frameworks (use jido_ai instead)
- Complex reasoning (use jido_ai's strategies)
- Multi-provider access (use jido_ai's abstraction)

### Key Capabilities

✅ **Agent orchestration primitives**
✅ **Tool integration framework**
✅ **Built-in telemetry** (observability)
✅ **Robust error handling**
✅ **Testable design**
✅ **Clear developer experience**

### Quick Start

```elixir
# mix.exs
{:swarm_ex, "~> 0.2.0"}
```

```elixir
defmodule MyApp.Agents.SearchAgent do
  use SwarmEx.Agent,
    name: "Search Agent",
    description: "Searches codebase for relevant information"

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_message(message, state) do
    # Process message and return response
    {:reply, result, state}
  end
end
```

### Integration with ai-rules

**Plan Mode**: Use swarm_ex for lightweight agent coordination in architecture planning

**Build Mode**: Use swarm_ex to coordinate multiple specialized agents during implementation

**Review Mode**: Verify agent coordination patterns and observability

### Resources

- HexDocs: https://hexdocs.pm/swarm_ex
- GitHub: https://github.com/nrrso/swarm_ex
- Stars: 83 stars, 8 forks (proven adoption)

---

## Tool 4: Codicil (Elixir-Native Semantic Search)

### What It Is

Semantic code search and analysis for Elixir projects via MCP. Uses compiler-level analysis for deep code understanding without external dependencies.

### When to Use

**Best For**:
- Finding functions by behavior (not just name)
- Dependency analysis (function call graphs, module relationships)
- Code relationship understanding
- Elixir-specific code analysis
- Compiler-level indexing (automatic during compilation)

**Avoid For**:
- Universal semantic search (use Serena or Probe)
- Cross-language search (use Codicil for Elixir only)
- Runtime database access (use jido_ai tools)

### Key Capabilities

✅ **Semantic function search** (find_similar_functions)
✅ **Dependency analysis** (list_function_callers, list_function_callees)
✅ **Module analysis** (list_module_dependencies)
✅ **Function source retrieval** (get_function_source_code)
✅ **Compiler-level indexing** (automatic via tracers)
✅ **Multi-LLM support** (Anthropic, OpenAI, Cohere, Google, Grok)
✅ **Local SQLite** + vector search

### Quick Start

```elixir
# mix.exs
{:codicil, "~> 0.7", only: [:dev, :test]}

# Initialize database
mix codicil.setup

# Configure environment
export CODICIL_LLM_PROVIDER=openai
export OPENAI_API_KEY=your_key

# Enable compiler tracer in mix.exs
defp elixirc_options(_env), do: [tracers: [Codicil.Tracer]]
```

```elixir
# Phoenix router (if using Phoenix)
if Code.ensure_loaded?(Codicil) do
  plug Codicil.Plug
end
```

### Integration with ai-rules

**Plan Mode**: Use Codicil for deep code understanding during architecture planning

**Build Mode**: Use Codicil for dependency analysis and refactoring support

**Review Mode**: Use Codicil for cross-reference code pattern verification

### Advantages Over mgrep/Serena

✅ **Elixir-native** (vs mgrep's Node.js)
✅ **Compiler-level** (vs external search tools)
✅ **Multi-LLM support** (flexible provider choice)
✅ **No embeddings required** (uses local SQLite)
✅ **Local-first** (runs entirely on your machine)

### Resources

- HexDocs: https://hexdocs.pm/codicil
- GitHub: https://github.com/E-xyza/codicil
- Stars: 41 stars, 2 forks (proven adoption)
- License: MIT (permissive)

---

## Tool 5: Probe (AST-Aware Code Search - Backup)

### What It Is

Local, AI-ready code intelligence tool combining ripgrep speed with tree-sitter AST parsing. Works without embeddings generation, providing instant semantic search with AST-aware pattern matching.

### When to Use

**Best For**:
- Backup semantic search when mgrep is unavailable
- Multi-language projects (polyglot repos)
- AST pattern matching (find specific code structures)
- Token-aware search for AI context windows

**Avoid For**:
- Elixir-specific search (use Codicil instead)
- Compiler-level analysis (use Codicil instead)
- Complex multi-file refactor (use Serena instead)

### Key Capabilities

✅ **Semantic code search** (natural language queries)
✅ **AST-aware pattern matching** (code structures, not text)
✅ **Elastic search syntax** (operators, boolean logic)
✅ **Token-aware results** (limits to fit AI context)
✅ **MCP server** (via npx)
✅ **No indexing required** (works directly on code)
✅ **Language-agnostic** (30+ languages via tree-sitter)

### Quick Start

```bash
# Install via npx
npx -y @buger/probe-mcp

# Configure MCP client
{
  "mcpServers": {
    "probe": {
      "type": "local",
      "command": ["npx", "-y", "@buger/probe-mcp"]
    }
  }
}
```

### MCP Tools

- **search_code**: Semantic search with Elasticsearch-like syntax
- **query_code**: Find specific code structures (AST patterns)
- **extract_code**: Extract code blocks from files

### Search Examples

```bash
# Basic semantic search
probe search "error handling" ./src

# Token-limited search
probe search "authentication" --max-tokens 8000 ./src

# Elastic search syntax
probe search "(login OR auth) AND NOT test" ./src

# AST pattern for functions
probe query -p "fn $NAME($PARAMS) $$$BODY" ./src

# Extract by line number
probe extract src/auth.js:15

# Extract by function name
probe extract "src/main.rs#authenticateUser"
```

### Integration with ai-rules

**Plan Mode**: Use Probe for broad code discovery when exploring new codebases

**Build Mode**: Use Probe as backup when mgrep fails or for polyglot projects

**Review Mode**: Use Probe for AST pattern verification alongside Codicil

### Resources

- Website: https://probelabs.com/
- GitHub: https://github.com/buger/probe
- License: Apache 2.0 (permissive)

---

## Tool Stack by Development Phase

### Plan Mode (Architecture & Design)

| Need | Primary Tool | Supporting Tool | Rationale |
|-------|-------------|----------------|----------|
| **Code understanding** | Codicil | jido_ai | Compiler-level + agent analysis |
| **Architecture patterns** | jido_ai | swarm_ex | Multi-agent reasoning + orchestration |
| **Custom MCP servers** | anubis-mcp | jido_ai | Full SDK + agent framework |

### Build Mode (Implementation & Coding)

| Need | Primary Tool | Supporting Tool | Rationale |
|-------|-------------|----------------|----------|
| **Semantic search** | Codicil | mgrep | Elixir-native + universal backup |
| **Dependency analysis** | Codicil | - | Code relationship understanding |
| **Multi-agent coordination** | jido_ai | swarm_ex | Advanced reasoning + lightweight orchestration |
| **Multi-file refactor** | Serena | - | AST-aware editing |
| **AST patterns** | Probe | Codicil | Code structure matching |

### Review Mode (Quality Assurance)

| Need | Primary Tool | Supporting Tool | Rationale |
|-------|-------------|----------------|----------|
| **Cross-reference** | Codicil | mgrep | Pattern verification |
| **Consistency check** | jido_ai | swarm_ex | Agent behavior validation |
| **Architecture review** | jido_ai | - | Reasoning quality assessment |

---

## Integration Checklist

### Setup Phase
- [ ] Install anubis_mcp dependency
- [ ] Install jido_ai dependency
- [ ] Install swarm_ex dependency
- [ ] Install codicil dependency
- [ ] Verify Probe installation (npx)

### Configuration Phase
- [ ] Update project_requirements.md with new tools
- [ ] Update opencode_mcp.json with all tools
- [ ] Configure environment variables for each tool
- [ ] Update AGENTS.md with tool workflows

### Documentation Phase
- [ ] Create anubis_mcp SKILL.md
- [ ] Create jido_ai SKILL.md
- [ ] Create swarm_ex SKILL.md
- [ ] Create codicil SKILL.md
- [ ] Create probe SKILL.md
- [ ] Update tools/README.md with tool overview

### Testing Phase
- [ ] Test anubis-mcp with Phoenix integration
- [ ] Test jido_ai with multiple providers
- [ ] Test swarm_ex agent coordination
- [ ] Test codicil indexing and search
- [ ] Validate Probe MCP server connection

### Template Updates
- [ ] Update Phoenix+Ash template with new tools
- [ ] Update Phoenix basic template with new tools
- [ ] Update Elixir library template with new tools

---

## Migration Notes

**Arcana Removal**:
- Arcana session files deleted
- Arcana references removed from MCP_COMPARISON.md
- Disclaimer added: Arcana removed due to domain mismatch (data science vs Elixir development)

**New Tools Strategy**:
- All 5 new tools are Elixir-native (except Probe)
- Follow source repositories for updates
- Use upstream versions when available (consider for jido_ai and anubis-mcp)
- Note license compatibility: Apache 2.0, MIT, LGPL v3

---

## Next Steps

1. Review individual SKILL.md files for each tool
2. Update AGENTS.md with comprehensive tool usage guidelines
3. Create example projects demonstrating tool combinations
4. Document common workflows (Plan → Build → Review)
5. Provide troubleshooting guide for each tool

---

## Resources

### Tool Documentation
- Anubis MCP: https://hexdocs.pm/anubis_mcp
- Jido AI: https://hexdocs.pm/jido_ai
- Swarm Ex: https://hexdocs.pm/swarm_ex
- Codicil: https://hexdocs.pm/codicil
- Probe: https://probelabs.com/

### Integration Guides
- AGENTS.md (overall agent guidelines)
- Project Requirements (tool-specific configuration)
- Tool-specific SKILL.md files

### Related Documentation
- MCP_COMPARISON.md (Serena, Tidewave, Hermes, new tools)
- Migration Guide (Arcana removal)
- Tool Combination Examples

---

## Support

For issues or questions about new tools integration:
1. Check individual SKILL.md files for tool-specific help
2. Review upstream documentation
3. Check GitHub issues for each tool
4. Consult ai-rules AGENTS.md for workflow guidance

---

**Last Updated**: January 16, 2026
