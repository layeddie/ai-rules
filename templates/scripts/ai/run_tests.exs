#!/usr/bin/env elixir
# Scoped test runner for agents. Limits to a file or pattern to avoid full-suite cost.
# Usage examples:
#   mix run scripts/ai/run_tests.exs -- --file test/my_test.exs
#   mix run scripts/ai/run_tests.exs -- --pattern "user*"

Mix.start()
Mix.Task.run("app.start")

{opts, _, _} = OptionParser.parse!(System.argv(), strict: [file: :string, pattern: :string])

args =
  case {opts[:file], opts[:pattern]} do
    {file, nil} when is_binary(file) -> [file]
    {nil, pattern} when is_binary(pattern) -> ["--only", pattern]
    _ -> raise "Provide --file or --pattern"
  end

{out, status} = System.cmd("mix", ["test" | args], stderr_to_stdout: true)
IO.write(out)
System.halt(status)
