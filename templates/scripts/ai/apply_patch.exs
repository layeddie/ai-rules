#!/usr/bin/env elixir
# Minimal safe writer: replaces a file's content only if path matches allowlist.
# Usage: MIX_ENV=dev mix run scripts/ai/apply_patch.exs -- --path lib/foo.ex < new_content

Mix.start()

{:ok, _} = Application.ensure_all_started(:mix)

{opts, _, _} = OptionParser.parse!(System.argv(), strict: [path: :string])
path = opts[:path] || raise "--path is required"
abs = Path.expand(path)
root = File.cwd!()
allowlist = Path.join([root, "ai", "policies", "allowlist.txt"])

allowed? =
  allowlist
  |> File.read!()
  |> String.split("\n", trim: true)
  |> Enum.reject(&String.starts_with?(&1, "#"))
  |> Enum.any?(fn glob ->
    :ok == :filelib.wildcard(Path.join(root, glob)) |> Enum.find(fn allowed -> abs == Path.expand(allowed) end) |> case do
      nil -> false
      _ -> true
    end
  end)

unless allowed? do
  IO.puts(:stderr, "Path not allowed by ai/policies/allowlist.txt: #{path}")
  System.halt(1)
end

content = IO.read(:stdio, :all)
backup = abs <> ".bak"
if File.exists?(abs), do: File.cp!(abs, backup)
File.write!(abs, content)
IO.puts("Wrote #{Path.relative_to(abs, root)} (backup at #{Path.relative_to(backup, root)})")
