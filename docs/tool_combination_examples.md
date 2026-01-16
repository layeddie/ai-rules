# Tool Combination Examples for ai-rules

**Purpose**: Examples of how to combine multiple new Elixir-native tools for common workflows

## Overview

This document provides concrete examples of combining the 5 new Elixir-native tools (anubis-mcp, jido_ai, swarm_ex, codicil, probe) with existing tools (mgrep, Serena, Hermes) for comprehensive ai-rules workflows.

---

## Example 1: Architecture Planning (Plan Mode)

### Tools: Codicil + Jido AI

### Workflow
1. Use Codicil for deep code understanding (compiler-level analysis)
2. Use Jido AI agents for multi-agent architecture exploration
3. Generate architecture recommendation with Chain-of-Thought reasoning

### Implementation

```elixir
defmodule MyApp.Architecture do
  alias Jido.AI.{Model, Prompt}
  alias Jido.AI.Actions.ReqLlm.ChatCompletion
  alias Jido.AI.Runners.ChainOfThought

  @doc """
  Plan architecture using Codicil + Jido AI
  """
  def plan_architecture(module_name, config \\ %{}) do
    # Step 1: Deep code understanding via Codicil
    {:ok, dependencies} = Codicil.MCP.Tools.ListModuleDependencies.call(%{
      moduleName: module_name
    })
    
    {:ok, function_info} = Codicil.MCP.Tools.GetFunctionSourceCode.call(%{
      moduleName: module_name,
      functionName: "init",
      arity: 1
    })
    
    # Step 2: Multi-agent analysis via Jido AI
    {:ok, model} = Model.from({:anthropic, [model: "claude-3-5-sonnet"]})
    
    system_prompt = Prompt.new(:system, """
    You are an expert Elixir/BEAM architect.
    Analyze the following module dependencies and function implementation.
    Recommend supervision tree structure and fault tolerance patterns.
    """)
    
    user_prompt = Prompt.new(:user, """
    Module: #{module_name}
    
    Dependencies:
    #{Enum.map(dependencies, &"  - #{&1.module_name} (#{&1.dependency_type})") |> Enum.join("\n")}
    
    Function implementation:
    #{function_info.source_code}
    
    Please recommend:
    1. Appropriate supervision tree structure
    2. OTP patterns for fault tolerance
    3. Separation of concerns
    4. Resource boundaries
    """)
    
    # Step 3: Chain-of-Thought reasoning
    {:ok, result} = ChainOfThought.run(%{
      problem: user_prompt,
      llm: model,
      max_iterations: 5,
      system_prompt: system_prompt
    })
    
    {:ok, result}
  end
end
```

### Usage in Plan Mode

```bash
# Start plan session
opencode --config .opencode/opencode.plan.json

# Ask for architecture planning
"Plan architecture for MyApp.Accounts module using Codicil + Jido AI"

# Output will include:
# - Codicil dependency analysis
# - Jido AI multi-agent reasoning
# - Chain-of-Thought step-by-step architecture plan
```

---

## Example 2: Implementation Coordination (Build Mode)

### Tools: Anubis MCP + Jido AI + Swarm Ex

### Workflow
1. Build custom MCP server with Anubis MCP
2. Use Jido AI agents to coordinate implementation
3. Use Swarm Ex for task delegation to specialized agents

### Implementation

```elixir
# Custom Ecto MCP server using Anubis MCP
defmodule MyApp.MCP.EctoTools do
  use Anubis.Server,
    name: "Ecto Tools",
    version: "1.0.0",
    capabilities: [:tools]

  @impl true
  def init(_client_info, frame) do
    {:ok, frame
      |> assign(counter: 0)
      |> register_tool("execute_query",
        input_schema: %{
          query: {:required, :string, description: "Ecto query to execute"}
        },
        annotations: %{read_only: true},
        description: "Execute safe Ecto queries for analysis")
      )
  end

  @impl true
  def handle_tool("execute_query", %{query: query}, frame) do
    # Execute safe Ecto queries (SELECT only)
    case Ecto.Adapters.SQL.query(Repo, query, []) do
      {:ok, %{rows: rows, num_rows: num}} ->
        {:reply, %{results: rows, count: num}, assign(frame, counter: frame.assigns.counter + 1)}
      
      {:error, error} ->
        {:reply, %{error: inspect(error)}, frame}
    end
  end
end

# Agent coordination with Swarm Ex
defmodule MyApp.Agents.Coordinator do
  use SwarmEx.Agent,
    name: "Implementation Coordinator",
    description: "Coordinates implementation agents using Jido AI + Anubis MCP"

  @impl true
  def init(state) do
    {:ok, %{state | agents: [], tasks: []}}
  end

  @impl true
  def handle_message({:start_implementation, module_name, feature}, state) do
    # Step 1: Analyze code using Codicil
    {:ok, similar_funcs} = Codicil.MCP.Tools.FindSimilarFunctions.call(%{
      description: "similar implementation patterns for #{feature}"
    })
    
    # Step 2: Create implementation plan with Jido AI
    {:ok, plan} = create_implementation_plan(module_name, feature, similar_funcs)
    
    # Step 3: Delegate to specialized Swarm Ex agents
    Enum.each(plan.tasks, fn task ->
      {:ok, _agent} = SwarmEx.Agent.start_link(
        name: task.name,
        handler: task.handler,
        args: task.args
      )
    end)
    
    {:reply, %{status: :started, plan: plan}, state}
  end

  defp create_implementation_plan(module_name, feature, similar_funcs) do
    alias Jido.AI.{Model, Prompt}
    alias Jido.AI.Actions.ReqLlm.ChatCompletion
    alias Jido.AI.Runners.ReAct

    {:ok, model} = Model.from({:anthropic, [model: "claude-3-5-sonnet"]})
    
    prompt = Prompt.new(:user, """
    Create implementation plan for:
    - Module: #{module_name}
    - Feature: #{feature}
    
    Reference implementations:
    #{Enum.map(similar_funcs, &"  - #{&1.module_name}.#{&1.function_name}/#{&1.arity}") |> Enum.join("\n")}
    
    Break down into specific tasks with agent assignments.
    """)
    
    {:ok, result} = ChatCompletion.run(%{model: model, prompt: prompt}, %{})
    parse_implementation_plan(result.content)
  end
end
```

### Usage in Build Mode

```bash
# Start build session
opencode --config .opencode/opencode.build.json

# Ask for implementation coordination
"Implement user authentication feature using Anubis MCP + Jido AI + Swarm Ex"

# Output will include:
# - Anubis MCP Ecto tools for database analysis
# - Jido AI ReAct reasoning for task breakdown
# - Swarm Ex agent coordination for parallel tasks
```

---

## Example 3: Code Review (Review Mode)

### Tools: Codicil + mgrep + Jido AI

### Workflow
1. Use Codicil to find related functions
2. Use mgrep to verify patterns across codebase
3. Use Jido AI for consistency checking across agents

### Implementation

```elixir
defmodule MyApp.Review do
  alias Codicil.MCP.Tools

  @doc """
  Review code using Codicil + mgrep + Jido AI
  """
  def review_function(module_name, function_name, arity) do
    # Step 1: Find related functions via Codicil
    {:ok, similar_funcs} = Codicil.MCP.Tools.FindSimilarFunctions.call(%{
      description: "functions similar to #{module_name}.#{function_name}"
    })
    
    # Step 2: Get caller graph via Codicil
    {:ok, callers} = Codicil.MCP.Tools.ListFunctionCallers.call(%{
      moduleName: module_name,
      functionName: function_name,
      arity: arity
    })
    
    # Step 3: Verify patterns with mgrep
    # Use bash tool to run mgrep
    {mgrep_output, 0} = System.cmd("mgrep", [
      "def #{function_name}",
      "lib/"
    ])
    
    # Step 4: Analyze consistency with Jido AI
    analysis = analyze_consistency(module_name, function_name, arity, similar_funcs, callers, mgrep_output)
    
    {:ok, %{
      similar_functions: similar_funcs,
      callers: callers,
      grep_matches: mgrep_output,
      consistency_analysis: analysis
    }}
  end

  defp analyze_consistency(module_name, function_name, arity, similar_funcs, callers, grep_matches) do
    alias Jido.AI.{Model, Prompt}
    alias Jido.AI.Actions.ReqLlm.ChatCompletion
    alias Jido.AI.Runners.SelfConsistency

    {:ok, model} = Model.from({:anthropic, [model: "claude-3-5-sonnet"]})
    
    prompt = Prompt.new(:user, """
    Review consistency of function:
    - Function: #{module_name}.#{function_name}/#{arity}
    
    Similar functions found:
    #{Enum.map(similar_funcs, &"  - #{&1.module_name}.#{&1.function_name}/#{&1.arity}") |> Enum.join("\n")}
    
    Callers (#{length(callers)} found):
    #{Enum.take(callers, 5) |> Enum.map(&"  - #{&1.module_name}.#{&1.function_name}/#{&1.arity}") |> Enum.join("\n")}
    
    mgrep matches:
    #{grep_matches}
    
    Identify:
    1. Naming consistency issues
    2. Pattern violations
    3. Potential refactoring opportunities
    """)
    
    # Use Self-Consistency reasoning for robust review
    {:ok, result} = SelfConsistency.run(%{
      problem: prompt,
      llm: model,
      paths: 3
    })
    
    result
  end
end
```

### Usage in Review Mode

```bash
# Start review session
opencode --config .opencode/opencode.review.json

# Ask for code review
"Review MyApp.Accounts.User.create function using Codicil + mgrep + Jido AI"

# Output will include:
# - Codicil similar functions and call graph
# - mgrep pattern matches
# - Jido AI Self-Consistency reasoning across multiple analysis paths
```

---

## Example 4: Multi-Language Search

### Tools: Probe + Codicil

### Workflow
1. Use Probe for non-Elixir languages
2. Use Codicil for Elixir-specific analysis
3. Combine results for comprehensive view

### Implementation

```elixir
defmodule MyApp.Search do
  @doc """
  Search codebase using Probe (multi-language) + Codicil (Elixir-native)
  """
  def search_codebase(query, search_paths \\ []) do
    # Step 1: Search Elixir code with Codicil
    elixir_results = search_elixir(query)
    
    # Step 2: Search other languages with Probe
    probe_results = search_with_probe(query, search_paths)
    
    # Step 3: Combine and prioritize results
    combined_results = combine_and_prioritize(elixir_results, probe_results)
    
    {:ok, combined_results}
  end

  defp search_elixir(query) do
    # Use Codicil for semantic search
    {:ok, functions} = Codicil.MCP.Tools.FindSimilarFunctions.call(%{
      description: query,
      limit: 10
    })
    
    {:ok, functions}
  end

  defp search_with_probe(query, search_paths) do
    # Use Probe MCP server for multi-language search
    # Probe search_code tool:
    #   - path: project root
    #   - query: search query
    #   - maxTokens: token limit
    
    # Call Probe via Anubis MCP or direct MCP call
    results = Enum.flat_map(search_paths, fn path ->
      case Probe.MCP.Tools.SearchCode.call(%{
        path: path,
        query: query,
        maxTokens: 8000
      }) do
        {:ok, search_results} -> search_results.results
        {:error, _} -> []
      end
    end)
    
    results
  end

  defp combine_and_prioritize(elixir_results, probe_results) do
    # Prioritize Elixir results from Codicil (more accurate)
    # Include Probe results for other languages
    prioritized = [
      elixir_results: Enum.map(&%{
        source: :codicil,
        score: &1.similarity_score,
        result: &1
      }),
      probe_results: Enum.map(&%{
        source: :probe,
        score: &1.score,
        result: &1
      })
    ]
    |> List.flatten()
    |> Enum.sort_by(& &1.score, :desc)
    
    prioritized
  end
end
```

### Usage in Any Mode

```bash
# Use search tool
"Search codebase for 'user authentication' patterns using Probe + Codicil"

# Output will include:
# - Codicil Elixir-specific semantic search results
# - Probe multi-language search results (Python, TypeScript, etc.)
# - Combined and prioritized results based on relevance
```

---

## Example 5: Advanced Multi-Agent Orchestration

### Tools: Jido AI + Swarm Ex + Anubis MCP + Codicil

### Workflow
1. Use Jido AI with Tree-of-Thoughts for complex reasoning
2. Use Swarm Ex for agent coordination
3. Use Anubis MCP to expose custom tools to agents
4. Use Codicil for code understanding

### Implementation

```elixir
# Swarm Ex agents for different roles
defmodule MyApp.Agents.Planner do
  use SwarmEx.Agent,
    name: "Planner Agent",
    description: "Plans implementation steps using Tree-of-Thoughts"

  @impl true
  def handle_message({:plan_feature, feature}, state) do
    # Use Jido AI Tree-of-Thoughts for complex planning
    {:ok, plan} = Jido.AI.Runners.TreeOfThoughts.run(%{
      problem: "Plan implementation of #{feature}",
      llm: Jido.AI.Model.get_default(),
      max_depth: 3
    })
    
    {:reply, plan, state}
  end
end

defmodule MyApp.Agents.Analyst do
  use SwarmEx.Agent,
    name: "Analyst Agent",
    description: "Analyzes code using Codicil"

  @impl true
  def handle_message({:analyze_code, module_name}, state) do
    # Use Codicil for code analysis
    {:ok, dependencies} = Codicil.MCP.Tools.ListModuleDependencies.call(%{
      moduleName: module_name
    })
    
    {:reply, dependencies, state}
  end
end

defmodule MyApp.Agents.ToolProvider do
  use SwarmEx.Agent,
    name: "Tool Provider Agent",
    description: "Provides MCP tools via Anubis MCP"

  @impl true
  def handle_message({:provide_tools}, state) do
    # Anubis MCP server exposes tools
    tools = MyApp.MCP.EctoTools.list_tools()
    
    {:reply, tools, state}
  end
end

# Coordinator
defmodule MyApp.Coordinator do
  use SwarmEx.Agent,
    name: "Master Coordinator",
    description: "Coordinates all agents"

  @impl true
  def init(state) do
    # Start specialized agents
    {:ok, planner} = SwarmEx.Agent.start_link(MyApp.Agents.Planner)
    {:ok, analyst} = SwarmEx.Agent.start_link(MyApp.Agents.Analyst)
    {:ok, tool_provider} = SwarmEx.Agent.start_link(MyApp.Agents.ToolProvider)
    
    {:ok, %{state |
      agents: [planner, analyst, tool_provider]
    }}
  end

  @impl true
  def handle_message({:coordinate_feature, feature}, state) do
    # 1. Plan with Tree-of-Thoughts
    GenServer.call(state.agents[:planner], {:plan_feature, feature})
    
    # 2. Analyze code with Codicil
    GenServer.call(state.agents[:analyst], {:analyze_code, feature})
    
    # 3. Get available tools from Anubis MCP
    GenServer.call(state.agents[:tool_provider], :provide_tools)
    
    # 4. Execute coordinated workflow
    {:reply, :coordinated, state}
  end
end
```

### Usage in Build Mode

```bash
# Start build session
opencode --config .opencode/opencode.build.json

# Request multi-agent coordination
"Coordinate implementation of payment processing using Jido AI + Swarm Ex + Anubis MCP + Codicil"

# Output will include:
# - Jido AI Tree-of-Thoughts for complex planning
# - Swarm Ex agent coordination across specialized roles
# - Anubis MCP custom tools (Ecto queries, code analysis)
# - Codicil code understanding (dependencies, relationships)
```

---

## Tool Stack Decision Guide

### Choose Primary Tool by Use Case

| Use Case | Primary Tool | Supporting Tools | Reasoning Strategy |
|-----------|----------------|-------------------|-------------------|
| **Architecture planning** | Codicil | Jido AI | Chain-of-Thought |
| **Feature implementation** | Anubis MCP | Jido AI + Swarm Ex | ReAct |
| **Code review** | Codicil | mgrep + Jido AI | Self-Consistency |
| **Multi-language search** | Probe | Codicil | - |
| **Complex coordination** | Jido AI | Swarm Ex + Anubis MCP | Tree-of-Thoughts |
| **Quick analysis** | mgrep | - | - |

### Tool Complementarity

- **Codicil + mgrep**: Deep Elixir analysis + quick pattern matching
- **Codicil + jido_ai**: Compiler-level + multi-provider LLM reasoning
- **jido_ai + swarm_ex**: Advanced reasoning + lightweight orchestration
- **anubis_mcp + jido_ai**: Custom MCP tools + agent framework
- **Probe + Codicil**: Multi-language + Elixir-specific

### Performance Characteristics

| Tool | Token Efficiency | Accuracy | Setup Complexity |
|-------|------------------|----------|------------------|
| **Codicil** | High (local SQLite) | High (compiler-level) | Low (automatic) |
| **jido_ai** | Medium (depends on provider) | Very High (advanced reasoning) | Medium (provider config) |
| **swarm_ex** | High (lightweight) | High (testable design) | Low (Elixir native) |
| **anubis_mcp** | High (custom tools) | High (Phoenix integration) | Medium (build server) |
| **Probe** | Medium (no embeddings) | High (AST-aware) | Low (npx) |

---

## Resource Requirements

### System Requirements
- **Elixir**: ~> 1.17 (for all Elixir tools)
- **OTP**: 26+ (for OTP patterns)
- **Node.js**: 18+ (for Probe via npx)
- **Python**: 3.10+ (optional, for Codicil embeddings)

### Storage Requirements
- **Codicil SQLite**: ~100MB for indexed code
- **Ecto migrations**: Additional for Codicil tables
- **Vector embeddings**: ~50MB for codicil database

### API Requirements
- **Optional**: OpenAI API key (for Codicil LLM, if not using local)
- **Optional**: Anthropic API key (for jido_ai)
- **Optional**: Google API key (for jido_ai)
- **Local LLMs**: Ollama, LM Studio supported (via jido_ai)

---

## Integration Testing

```bash
# Test individual tools
mix test test/anubis_mcp_integration_test.exs
mix test test/jido_ai_integration_test.exs
mix test test/swarm_ex_integration_test.exs
mix test test/codicil_integration_test.exs

# Test tool combinations
mix test test/multi_agent_integration_test.exs
mix test test/architecture_planning_test.exs
mix test test/code_review_test.exs

# Validate all tools
bash scripts/validate_new_tools.sh
```

---

## Troubleshooting

### Common Issues

**Codicil not indexing code**:
- Verify tracer is enabled in mix.exs
- Run `mix compile` to trigger indexing
- Check environment variables: CODICIL_LLM_PROVIDER

**Jido AI agent failing**:
- Verify API keys are set
- Check provider configuration in config/dev.exs
- Monitor telemetry for token usage

**Swarm Ex agents not starting**:
- Verify agent modules are in application supervisor
- Check agent name conflicts
- Monitor telemetry for start failures

**Probe MCP not connecting**:
- Verify npx is installed
- Check MCP client configuration
- Increase timeout for large codebases

**Anubis MCP server not accessible**:
- Verify Phoenix router includes MCP forward route
- Check transport configuration (HTTP vs SSE)
- Monitor application logs for errors

---

## Best Practices

1. **Start simple**: Use single tool first, then add complexity
2. **Test incrementally**: Validate each tool before combining
3. **Monitor performance**: Track token usage and response times
4. **Fail gracefully**: Use supervisor trees for fault tolerance
5. **Leverage strengths**:
   - Codicil for Elixir-specific code
   - Probe for multi-language
   - jido_ai for complex reasoning
   - swarm_ex for lightweight orchestration
   - anubis_mcp for custom MCP tools

---

## Next Steps

1. Review individual SKILL.md files for tool-specific usage
2. Implement integration tests for each tool combination
3. Document project-specific workflows
4. Monitor and optimize performance
5. Share patterns with team

---

**Last Updated**: January 16, 2026
