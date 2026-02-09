defmodule AiRulesAgent.ToolSchema do
  @moduledoc """
  Tiny helper to derive JSON Schemas for tool args from simple Elixir specs.

  Example:
      spec = %{n: :integer, message: :string, tags: {:list, :string}}
      schema = AiRulesAgent.ToolSchema.from_spec(spec)
  """

  @spec from_spec(map()) :: map()
  def from_spec(spec) when is_map(spec) do
    properties =
      Enum.into(spec, %{}, fn {name, type} ->
        {to_string(name), type_to_schema(type)}
      end)

    %{
      "type" => "object",
      "properties" => properties,
      "required" => required_fields(spec)
    }
  end

  defp required_fields(spec) do
    spec
    |> Enum.filter(fn {_k, v} -> not optional?(v) end)
    |> Enum.map(fn {k, _} -> to_string(k) end)
  end

  defp optional?({:optional, _}), do: true
  defp optional?(_), do: false

  defp type_to_schema({:optional, inner}), do: type_to_schema(inner)
  defp type_to_schema(:string), do: %{"type" => "string"}
  defp type_to_schema(:integer), do: %{"type" => "integer"}
  defp type_to_schema(:number), do: %{"type" => "number"}
  defp type_to_schema(:boolean), do: %{"type" => "boolean"}

  defp type_to_schema({:list, inner}) do
    %{"type" => "array", "items" => type_to_schema(inner)}
  end

  defp type_to_schema({:map, inner}) when is_map(inner) do
    from_spec(inner)
  end

  defp type_to_schema(_), do: %{"type" => "object"}
end
