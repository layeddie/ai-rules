defmodule TestProject.Application do
  use Application

  defp children do
    [
      # Registry for agents
      {Registry, keys: :unique, name: TestProject.Registry}
    ] ++ optional_children()
  end

  defp optional_children do
    children = []

    children =
      if Code.ensure_loaded?(Codicil) do
        children ++ [{Codicil.Plug, []}]
      else
        children
      end

    children =
      if Code.ensure_loaded?(Anubis.Server) do
        children ++ [{TestProject.MCPServer, []}]
      else
        children
      end

    children =
      if Code.ensure_loaded?(SwarmEx.Agent) do
        children ++ [{TestProject.Coordinator, []}]
      else
        children
      end

    children ++ [{Logger, level: :info}]
  end

  @impl true
  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: TestProject.Supervisor]
    Supervisor.start_link(children(), opts)
  end
end
