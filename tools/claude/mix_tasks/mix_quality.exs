defmodule Mix.Tasks.Quality.Check do
  @moduledoc """
  Optional custom checks to mirror Claude hooks outside the editor.

  How to use in a project (manual copy):
  1) Copy this file to `lib/mix/tasks/quality.check.ex` (or similar).
  2) In `mix.exs`, add to aliases:
       defp aliases do
         [
           quality: ["format --check-formatted", "credo --strict", "quality.check"]
         ] ++ existing_aliases()
       end
  3) Run with `mix quality`.

  Notes:
  - Relies on `rg` (ripgrep); falls back to `grep` if missing.
  - Skips `_build` and `deps` by default.
  """

  use Mix.Task

  @shortdoc "Runs ai-rules custom lint checks (missing @impl, hardcoded paths, etc.)"

  @checks [
    %{
      name: "missing_impl",
      pattern: "(?<!@impl true\\n)\\s*def (handle_call|handle_cast|handle_info|handle_event|handle_params|init|terminate)\\(",
      message: "Add @impl true above callbacks."
    },
    %{
      name: "hardcoded_paths",
      pattern: "\"/(Users|home|var|tmp)/",
      message: "Avoid hardcoded absolute paths; prefer config/Application.app_dir/1."
    },
    %{
      name: "hardcoded_sizes",
      pattern: "\\b(1_?0{6,}|[1-9][0-9]{6,})\\b",
      message: "Move upload/file size limits to config; avoid magic numbers."
    },
    %{
      name: "static_paths",
      pattern: "\"/assets/[^\"]+\"",
      message: "Ensure asset is listed in static_paths/0."
    },
    %{
      name: "nested_if",
      pattern: "if .*\\n\\s*if ",
      message: "Prefer pattern matching/guards over nested if/else."
    },
    %{
      name: "enum_chain",
      pattern: "Enum\\.(map|filter|reduce).*\\|>\\s*Enum\\.(map|filter|reduce)",
      message: "Consider a single Enum.reduce or a comprehension."
    },
    %{
      name: "string_concat_loop",
      pattern: "Enum\\.(map|each).*<>\"|\"<>",
      message: "Use IO lists for repeated string concatenation."
    }
  ]

  @doc false
  def run(_args) do
    Mix.shell().info("Running custom quality checks...")

    failures =
      @checks
      |> Enum.flat_map(&run_check/1)

    if failures == [] do
      Mix.shell().info("Custom checks passed.")
    else
      Enum.each(failures, fn {name, message, output} ->
        Mix.shell().error("[#{name}] #{message}")
        Mix.shell().error(String.trim(output))
      end)

      Mix.raise("quality.check failed (#{length(failures)} issues).")
    end
  end

  defp run_check(%{name: name, pattern: pattern, message: message}) do
    case ripgrep(pattern) do
      {:ok, ""} ->
        []

      {:ok, hits} ->
        [{name, message, hits}]

      {:error, reason} ->
        Mix.shell().error("[#{name}] check error: #{reason}")
        [{name, message, ""}]
    end
  end

  defp ripgrep(pattern) do
    rg = System.find_executable("rg")

    if rg do
      {out, status} =
        System.cmd(rg, [
          "--pcre2",
          "-n",
          pattern,
          "lib",
          "test",
          "--glob",
          "!.git",
          "--glob",
          "!deps/**",
          "--glob",
          "!_build/**"
        ])

      if status == 0, do: {:ok, out}, else: {:ok, ""}
    else
      # fallback to grep (less precise, still skips deps/_build)
      {out, status} =
        System.cmd("grep", [
          "-R",
          "-nE",
          pattern,
          "lib",
          "test",
          "--exclude-dir",
          "deps",
          "--exclude-dir",
          "_build",
          "--exclude-dir",
          ".git"
        ])

      if status == 0, do: {:ok, out}, else: {:ok, ""}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end
end
