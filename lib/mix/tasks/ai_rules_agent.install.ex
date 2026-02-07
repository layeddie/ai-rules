defmodule Mix.Tasks.AiRulesAgent.Install do
  @moduledoc """
  Copies ai/ scaffold and scripts into the host project.

  Usage: mix ai_rules_agent.install
  """
  use Mix.Task
  @shortdoc "Install AI agent scaffold"

  @files [
    {"templates/ai/README.md", "ai/README.md"},
    {"templates/ai/policies/allowlist.txt", "ai/policies/allowlist.txt"},
    {"templates/scripts/ai/dump_context.exs", "scripts/ai/dump_context.exs"},
    {"templates/scripts/ai/apply_patch.exs", "scripts/ai/apply_patch.exs"},
    {"templates/scripts/ai/run_tests.exs", "scripts/ai/run_tests.exs"},
    {"templates/scripts/ai/serve_agent.exs", "scripts/ai/serve_agent.exs"},
    {"templates/scripts/ai/serve_agent_stdio.exs", "scripts/ai/serve_agent_stdio.exs"}
  ]

  @impl true
  def run(_args) do
    app_root = File.cwd!()

    Enum.each(@files, fn {source, target} ->
      source_path = Path.join([__DIR__, "..", "..", "..", source])
      target_path = Path.join(app_root, target)
      target_dir = Path.dirname(target_path)
      File.mkdir_p!(target_dir)
      File.cp!(source_path, target_path)
      Mix.shell().info("wrote #{target_path}")
    end)

    Mix.shell().info("ai_rules_agent scaffold installed.")
  end
end
