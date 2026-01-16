# Codicil - Elixir-Native Semantic Code Search

## Overview
Semantic code search and analysis for Elixir projects via MCP (Model Context Protocol). Uses compiler-level analysis for deep code understanding without external dependencies.

**Source**: https://github.com/E-xyza/codicil

## When to Use
- Finding functions by behavior (not just name)
- Dependency analysis (function call graphs, module relationships)
- Code relationship understanding
- Elixir/BEAM native code analysis
- Compiler-level indexing (automatic during compilation)

## Key Capabilities
- ✅ Semantic function search (find_similar_functions)
- ✅ Dependency analysis:
  - list_function_callers
  - list_function_callees
  - list_module_dependencies
- ✅ Module analysis (list_module_dependencies)
- ✅ Function source retrieval (get_function_source_code)
- ✅ Compiler-level indexing (automatic via tracers)
- ✅ Multi-LLM support (Anthropic, OpenAI, Cohere, Google, Grok)
- ✅ Local SQLite + vector search
- ✅ No external dependencies (uses local SQLite)

## Quick Start
```elixir
# mix.exs
{:codicil, "~> 0.7", only: [:dev, :test]}
```

```elixir
# Initialize database
mix codicil.setup

# Configure environment
export CODICIL_LLM_PROVIDER=openai
export OPENAI_API_KEY=your_key

# Enable compiler tracer in mix.exs
defp elixirc_options(:prod), do: []
defp elixirc_options(_env), do: [tracers: [Codicil.Tracer]]

# Add to Phoenix router (if using Phoenix)
if Code.ensure_loaded?(Codicil) do
  plug Codicil.Plug
end
```

## MCP Tools

### find_similar_functions
Find functions by semantic description using vector similarity search.

```json
{
  "description": "functions that validate user input",
  "limit": 10
}
```

### list_function_callers
Find what calls a specific function (useful for debugging and impact analysis).

```json
{
  "moduleName": "MyApp.User",
  "functionName": "create",
  "arity": 1
}
```

### list_function_callees
Find what a function calls (useful for debugging execution paths).

```json
{
  "moduleName": "MyApp.Orders",
  "functionName": "process",
  "arity": 1
}
```

### list_module_dependencies
Analyze module dependencies (imports, aliases, uses, requires, runtime calls).

```json
{
  "moduleName": "MyApp.Accounts"
}
```

### get_function_source_code
Get complete function source code with module directives and location. Use this instead of grep or file reading.

```json
{
  "moduleName": "MyApp.User",
  "functionName": "create",
  "arity": 1
}
```

## Integration with ai-rules
- **Plan Mode**: Use Codicil for deep code understanding during architecture planning
- **Build Mode**: Use Codicil for dependency analysis during refactoring
- **Review Mode**: Use Codicil for cross-reference code patterns and consistency checking

### Agent Roles
- **Architect**: Analyze codebase structure and dependencies using Codicil
- **Orchestrator**: Use Codicil for dependency impact analysis before refactoring
- **Reviewer**: Verify no N+1 queries and proper module structure

### Tooling Integration
- Use Codicil as primary semantic search tool (Elixir-native)
- Use Codicil with jido_ai for reasoning + code understanding
- Use Codicil with swarm_ex for agent coordination + code analysis
- Use Codicil with anubis_mcp for MCP server + code understanding

## Advantages Over mgrep/Serena
✅ **Elixir-native** (vs mgrep's Node.js)
✅ **Compiler-level** (vs external search tools)
✅ **Multi-LLM support** (flexible provider choice)
✅ **No embeddings required** (uses local SQLite + tracers)
✅ **Local-first** (runs entirely on your machine)

## Workflow Example

### Architecture Planning (Plan Mode)
```elixir
defmodule MyApp.Architecture do
  alias Codicil.MCP.Tools

  def analyze_dependencies do
    {:ok, deps} = Codicil.MCP.Tools.ListModuleDependencies.call("MyApp.Accounts")
    
    deps
    |> Enum.each(fn dep ->
      IO.puts("#{dep.module_name} depends on: #{dep.dependencies}")
    end)
  end
end
```

### Refactoring Support (Build Mode)
```elixir
defmodule MyApp.Refactor do
  alias Codicil.MCP.Tools

  def extract_function_usage do
    {:ok, callers} = Codicil.MCP.Tools.ListFunctionCallers.call(%{
      moduleName: "MyApp.Orders",
      functionName: "process",
      arity: 1
    })
    
    {:ok, callees} = Codicil.MCP.Tools.ListFunctionCallees.call(%{
      moduleName: "MyApp.Orders",
      functionName: "process",
      arity: 1
    })
    
    # Analyze impact
    IO.puts("Called by: #{Enum.join(Enum.map(callers, & &1.name), ", ")}")
    IO.puts("Calls: #{Enum.join(Enum.map(callees, & &1.name), ", ")}")
  end
end
```

## Best Practices
- Use Codicil for Elixir-specific code analysis
- Leverage compiler-level indexing for deep understanding
- Analyze dependencies before refactoring (callers + callees)
- Use Codicil instead of mgrep for Elixir projects
- Combine with jido_ai for complex reasoning about code
- Verify function signatures with source code retrieval
- Monitor Codicil database size (~100MB typical)

## Troubleshooting
- Verify Codicil tracer is enabled in mix.exs
- Ensure environment variables are set (CODICIL_LLM_PROVIDER, OPENAI_API_KEY)
- Check Codicil database is initialized: `mix codicil.setup`
- Verify Phoenix router includes Codicil.Plug (if using Phoenix)
- Test Codicil MCP tools with sample queries
- Monitor indexing performance during compilation

## Resources
- HexDocs: https://hexdocs.pm/codicil
- GitHub: https://github.com/E-xyza/codicil
- Stars: 41 stars, 2 forks (proven adoption)
- License: MIT (permissive)
