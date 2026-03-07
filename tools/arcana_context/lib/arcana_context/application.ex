defmodule ArcanaContext.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        ArcanaContext.Repo,
        Arcana.TaskSupervisor
      ] ++ local_embedder_children()

    opts = [strategy: :one_for_one, name: ArcanaContext.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp local_embedder_children do
    case Application.get_env(:arcana, :embedder, :openai) do
      :local -> [Arcana.Embedder.Local]
      _ -> []
    end
  end
end
