defmodule AiRulesContext.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AiRulesContext.Repo
    ]

    opts = [strategy: :one_for_one, name: AiRulesContext.Supervisor]
    {:ok, _} = Supervisor.start_link(children, opts)

    # Start Arcana processes manually after supervisor is running
    {:ok, _} = Arcana.Embedder.Local.start_link([])
    {:ok, _} = Arcana.TaskSupervisor.start_link([])

    {:ok, children}
  end
end
