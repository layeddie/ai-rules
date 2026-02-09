defmodule AiRulesAgent.Tools.WebSearch do
  @moduledoc """
  Lightweight web search using DuckDuckGo's JSON API (no key required).

  Args:
    * `query` (required)
    * `limit` (optional, default 5)
  """

  @endpoint "https://api.duckduckgo.com/"

  def spec do
    %{
      fun: &run/1,
      schema_spec: %{
        query: :string,
        limit: {:optional, :integer}
      }
    }
  end

  def run(%{"query" => q} = args) do
    limit = Map.get(args, "limit", 5)
    req = Map.get(args, "req_mod", Req)

    case req.get(url: @endpoint, params: %{q: q, format: "json", no_html: 1, skip_disambig: 1}) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        body
        |> Map.get("RelatedTopics", [])
        |> Enum.flat_map(fn
          %{"Text" => text, "FirstURL" => url} -> [%{title: text, url: url}]
          %{"Topics" => topics} -> Enum.map(topics, &%{title: &1["Text"], url: &1["FirstURL"]})
          _ -> []
        end)
        |> Enum.take(limit)

      {:ok, %Req.Response{status: status}} ->
        {:error, {:http_status, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
