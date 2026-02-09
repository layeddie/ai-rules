defmodule AiRulesAgent.Tools.FileSearch do
  @moduledoc """
  Read-only file search respecting `ai/policies/allowlist.txt`.

  Args:
    * `pattern` (string, required)
    * `glob` (string, optional, default: \"lib/**/*.exs\")
    * `limit` (int, optional, default: 5)
  """

  @allowlist_path Path.expand("ai/policies/allowlist.txt", File.cwd!())

  def spec do
    %{
      fun: &run/1,
      schema_spec: %{
        pattern: :string,
        glob: {:optional, :string},
        limit: {:optional, :integer}
      }
    }
  end

  def run(%{"pattern" => pattern} = args) do
    glob = Map.get(args, "glob", "lib/**/*.{ex,exs}")
    limit = Map.get(args, "limit", 5)

    glob
    |> allowed_files()
    |> Stream.flat_map(fn path ->
      path
      |> File.stream!()
      |> Stream.with_index(1)
      |> Stream.filter(fn {line, _i} -> String.contains?(line, pattern) end)
      |> Stream.map(fn {line, i} -> %{file: path, line: i, snippet: String.trim(line)} end)
    end)
    |> Enum.take(limit)
  end

  defp allowed_files(glob) do
    allowed =
      @allowlist_path
      |> File.read!()
      |> String.split("\n", trim: true)
      |> Enum.reject(&String.starts_with?(&1, "#"))
      |> Enum.flat_map(&Path.wildcard(Path.expand(Path.join(File.cwd!(), &1))))
      |> MapSet.new()

    glob
    |> Path.wildcard()
    |> Enum.filter(&MapSet.member?(allowed, Path.expand(&1)))
  end
end
