#!/usr/bin/env elixir
# Generates small JSON manifests for AI agents (routes + Ash resources).
# Run with: mix run scripts/ai/dump_context.exs

Mix.start()
Mix.Task.run("app.start")

defmodule AIRules.ContextDump do
  @context_dir Path.join([File.cwd!(), "ai", "context"])

  def run do
    File.mkdir_p!(@context_dir)
    write_file("phoenix_routes.json", routes_payload())
    write_file("ash_resources.json", ash_payload())
    IO.puts("Wrote manifests to #{Path.relative_to(@context_dir, File.cwd!())}/*")
  end

  defp routes_payload do
    app = Mix.Project.config()[:app] |> to_string() |> Macro.camelize()
    router = Module.concat([app <> "Web", "Router"])

    routes =
      if Code.ensure_loaded?(router) and function_exported?(router, :__routes__, 0) do
        for %Phoenix.Router.Route{} = r <- router.__routes__() do
          %{
            verb: r.verb,
            path: r.path,
            plug: inspect(r.plug),
            action: r.plug_opts,
            pipe_through: r.pipe_through
          }
        end
      else
        []
      end

    %{generated_at: DateTime.utc_now(), router: inspect(router), routes: routes}
  end

  defp ash_payload do
    {:ok, modules} = :application.get_key(Mix.Project.config()[:app], :modules)

    ash_modules =
      modules
      |> Enum.filter(&Code.ensure_loaded?/1)
      |> Enum.filter(&function_exported?(&1, :__ash_resource__, 0))
      |> Enum.map(fn mod ->
        info = mod.__ash_resource__()
        %{
          module: inspect(mod),
          short_name: info.short_name,
          actions: Enum.map(info.actions, fn {name, action} -> %{name: name, type: action.type} end),
          attributes: Enum.map(info.attributes, &Map.take(&1, [:name, :type, :allow_nil]))
        }
      end)

    %{generated_at: DateTime.utc_now(), resources: ash_modules}
  rescue
    _ -> %{generated_at: DateTime.utc_now(), resources: []}
  end

  defp write_file(name, payload) do
    path = Path.join(@context_dir, name)
    json = Jason.encode!(payload, pretty: true)
    File.write!(path, json)
  end
end

AIRules.ContextDump.run()
