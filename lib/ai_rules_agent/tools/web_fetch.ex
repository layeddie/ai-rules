defmodule AiRulesAgent.Tools.WebFetch do
  @moduledoc """
  Simple read-only web fetch tool using Req.

  Accepts args: `%{"url" => "...", "limit" => 4000}` and returns a truncated body.
  """

  def spec do
    %{
      fun: &fetch/1,
      schema_spec: %{
        url: :string,
        limit: {:optional, :integer}
      }
    }
  end

  def fetch(%{"url" => url} = args) do
    limit = Map.get(args, "limit", 4000)

    case Req.get(url: url, receive_timeout: 5_000) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        body |> to_string() |> String.slice(0, limit)

      {:ok, %Req.Response{status: status}} ->
        {:error, {:http_status, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
