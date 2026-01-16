# Anubis MCP SDK

## Overview
Complete Elixir SDK for Model Context Protocol (MCP), providing both client and server implementations with Elixir's native concurrency and fault tolerance.

**Source**: https://github.com/zoedsoupe/anubis-mcp (upstream)  
**Fork**: https://github.com/layeddie/anubis-mcp (your fork)

## When to Use
- Building custom Elixir MCP servers
- Phoenix integration (HTTP/SSE transport)
- Domain-specific tools (e.g., Ecto analyzer, Phoenix LiveView inspector)
- Replacing Hermes with full customization control

## Key Capabilities
- ✅ Complete client + server implementation
- ✅ Phoenix integration (HTTP/SSE transport via Plug)
- ✅ Streamable HTTP support
- ✅ Tool registration with input schemas
- ✅ BEAM supervision trees
- ✅ Production-ready (error handling, telemetry)

## Quick Start
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
          query: {:required, :string, max: 150, description: "the text to be echoed"}
        },
        annotations: %{read_only: true},
        description: "echoes everything user says to LLM")
  end

  @impl true
  def handle_tool("my_tool", %{text: text}, frame) do
    Logger.info("This tool was called #{frame.assigns.counter + 1}")
    {:reply, text, assign(frame, counter: frame.assigns.counter + 1)}
  end
end

# Phoenix router
forward "/mcp", Anubis.Server.Transport.StreamableHTTP.Plug, server: MyApp.MCPServer
```

## Integration with ai-rules
- **Plan Mode**: Use anubis-mcp for custom MCP server development during architecture planning
- **Build Mode**: Build domain-specific Elixir MCP servers for ai-rules workflows (e.g., Ecto query analyzer, Phoenix LiveView inspector)
- **Review Mode**: Verify MCP server implementations follow OTP best practices

### Agent Roles
- **Architect**: Design MCP server architecture and tool schemas
- **Orchestrator**: Build and test custom MCP servers
- **Reviewer**: Validate MCP server implementations for production readiness

### Tooling Integration
- Use anubis-mcp with jido_ai for agent + MCP server workflows
- Use anubis-mcp with swarm_ex for multi-MCP server coordination

## Resources
- HexDocs: https://hexdocs.pm/anubis_mcp
- Upstream: https://github.com/zoedsoupe/anubis-mcp
- Examples: https://github.com/layeddie/anubis-mcp/tree/main/priv/dev

## License Notes
⚠️ **LGPL v3 (Copyleft License)**:
- Requires derivative works to be LGPL v3
- May not be suitable for commercial projects
- Consider using upstream zoedsoupe/anubis-mcp (MIT license) instead
- Or build your own SDK under MIT/Apache 2.0

## Common Patterns
- Tool registration with input schemas
- Request/response handling
- Error handling with supervision trees
- Telemetry integration
- Custom transport implementations

## Best Practices
- Use OTP supervision trees for fault tolerance
- Implement proper error handling in tool callbacks
- Add telemetry for observability
- Test MCP tools with ExUnit
- Document tool schemas clearly for LLM understanding

## Troubleshooting
- Ensure Phoenix router includes MCP forward route
- Verify MCP server is added to application supervisor
- Check for transport configuration errors (HTTP vs SSE)
- Monitor telemetry for performance issues
