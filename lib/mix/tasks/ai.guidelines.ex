defmodule Mix.Tasks.Ai.Guidelines do
  @moduledoc """
  Prints condensed AI coding guidelines for BEAM projects (OTP, Ash, Phoenix).
  Intended for agents or humans needing a quick reminder.
  """
  use Mix.Task
  @shortdoc "Print AI coding guidelines"

  @impl true
  def run(_args) do
    guidelines = [
      "Thin controllers; put business logic in Ash actions/resources.",
      "Supervise long-lived processes; keep callbacks non-blocking.",
      "Preload to avoid N+1; add indices for query filters.",
      "Use pattern matching and with/ok-error tuples for flow.",
      "Write tests mirroring lib/ structure; property tests for complex logic.",
      "Respect ai/policies allowlist; use fs_write_patch/patch endpoint for writes.",
      "Prefer scoped tests (file/tag) to full suite; run mix ai.test." ,
      "Refresh manifests after schema/route changes: mix ai.dump." 
    ]

    Enum.each(guidelines, &Mix.shell().info("- " <> &1))
  end
end
