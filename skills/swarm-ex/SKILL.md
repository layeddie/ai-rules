# SwarmEx Agent Orchestration

## Overview
Lightweight, controllable, and testable AI agent orchestration in Elixir. Provides primitives for creating and coordinating networks of AI agents, leveraging Elixir's native concurrency and fault tolerance.

**Source**: https://github.com/nrrso/swarm_ex

## When to Use
- Lightweight agent coordination (when jido_ai is overkill)
- Multi-agent task delegation
- Built-in telemetry and observability
- Testable agent workflows
- Custom agent development

## Key Capabilities
- ✅ Agent orchestration primitives
- ✅ Tool integration framework
- ✅ Built-in telemetry (observability)
- ✅ Robust error handling
- ✅ Clear developer experience

## Quick Start
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

## Integration with ai-rules
- **Plan Mode**: Use swarm_ex for lightweight agent coordination in architecture planning
- **Build Mode**: Use swarm_ex to coordinate multiple specialized agents during implementation
- **Review Mode**: Validate agent coordination patterns and observability

### Agent Roles
- **Orchestrator**: Use swarm_ex as primary orchestration layer for multi-agent workflows
- **Architect**: Design agent architectures using swarm_ex primitives
- **Reviewer**: Verify agent coordination and telemetry patterns

### Tooling Integration
- Use swarm_ex with jido_ai for advanced agent orchestration
- Use swarm_ex with anubis_mcp for agent + MCP server workflows
- Use swarm_ex with codicil for agent coordination with code understanding

## Agent Patterns

### Single Agent
```elixir
defmodule MyApp.SimpleAgent do
  use SwarmEx.Agent

  @impl true
  def init(state) do
    {:ok, %{state | counter: 0}}
  end

  @impl true
  def handle_message(message, state) do
    {:reply, "Processed: #{message}", %{state | counter: state.counter + 1}}
  end
end
```

### Multi-Agent Workflow
```elixir
defmodule MyApp.Coordinator do
  use SwarmEx.Agent

  @impl true
  def init(state) do
    {:ok, %{state | tasks: []}}
  end

  @impl true
  def handle_message(message, state) do
    case message do
      "start_task" ->
        {:noreply, %{state | tasks: state.tasks ++ [message.task]}}

      "complete_task" ->
        {:noreply, %{state | tasks: List.delete(state.tasks, message.task)}}

      _ ->
        {:reply, "Unknown command", state}
    end
  end
end
```

### Telemetry Integration
```elixir
defmodule MyApp.Telemetry do
  use SwarmEx.Telemetry

  @impl true
  def attach_handler(agent, handler) do
    SwarmEx.Telemetry.attach_handler(agent, handler)
  end

  def handle_event(event, metadata) do
    # Process telemetry events
    IO.inspect({event, metadata})
  end
end
```

## Best Practices
- Use lightweight agents for simple tasks
- Coordinate multiple agents for complex workflows
- Implement proper error handling in agent callbacks
- Add telemetry for observability (monitoring, debugging)
- Test agent interactions with ExUnit
- Use OTP supervision trees for fault tolerance
- Monitor agent performance and token usage
- Implement graceful shutdown and cleanup

## Observability
SwarmEx provides built-in telemetry hooks for monitoring:
- Agent lifecycle events (started, stopped, crashed)
- Message processing metrics (success, failure, latency)
- Task execution tracking
- Custom event handlers

## Example Metrics
```elixir
# Monitor agent performance
defmodule MyApp.Metrics do
  use SwarmEx.Telemetry

  def track_agent_lifecycle do
    attach_event_handlers()
  end
end
```

## Resources
- HexDocs: https://hexdocs.pm/swarm_ex
- GitHub: https://github.com/nrrso/swarm_ex
- Stars: 83 stars, 8 forks (proven adoption)

## Troubleshooting
- Verify agents are added to application supervisor
- Check telemetry is enabled
- Monitor agent lifecycle for crashes
- Verify message handlers are implemented correctly
- Test agent interactions with sample workflows
