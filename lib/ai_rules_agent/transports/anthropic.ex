defmodule AiRulesAgent.Transports.Anthropic do
  @moduledoc """
  Build an `llm_fun` for Anthropic Messages API via Req.
  """

  @endpoint "https://api.anthropic.com/v1/messages"

  @doc """
  Options:
  * `:model` (required)
  * `:api_key` (default from `ANTHROPIC_API_KEY`)
  * `:base_url` (override endpoint)
  * `:headers` (extra headers)
  * `:req` (Req-like module)
  """
  def llm_fun(opts) do
    model = Keyword.fetch!(opts, :model)
    api_key = Keyword.get(opts, :api_key, System.get_env("ANTHROPIC_API_KEY"))
    base_url = Keyword.get(opts, :base_url, @endpoint)
    extra_headers = Keyword.get(opts, :headers, %{})
    req_mod = Keyword.get(opts, :req, Req)

    fn %{messages: messages} = payload ->
      headers =
        %{
          "x-api-key" => api_key,
          "anthropic-version" => "2023-06-01",
          "content-type" => "application/json"
        }
        |> Map.merge(extra_headers)

      tools =
        payload
        |> Map.get(:tools, [])
        |> Enum.map(fn %{name: name} ->
          %{
            "name" => name,
            "input_schema" => %{
              "type" => "object",
              "properties" => %{},
              "additionalProperties" => true
            }
          }
        end)

      body =
        %{
          "model" => model,
          "messages" => to_anthropic(messages),
          "tools" => if(tools == [], do: nil, else: tools),
          "max_tokens" => 512
        }
        |> Enum.reject(fn {_k, v} -> is_nil(v) end)
        |> Map.new()

      case req_mod.post(url: base_url, headers: headers, json: body) do
        {:ok, %Req.Response{status: 200, body: %{"content" => content} = resp}} ->
          {:ok, decode_content(resp, content)}

        {:ok, %Req.Response{status: status, body: body}} ->
          {:error, {:http_error, status, body}}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp to_anthropic(messages) do
    Enum.map(messages, fn
      %{role: :user, content: c} -> %{"role" => "user", "content" => c}
      %{role: :assistant, content: c} -> %{"role" => "assistant", "content" => c}
      %{role: :tool, name?: name, content: c} -> %{"role" => "tool", "content" => [%{"type" => "tool_result", "tool_use_id" => name, "content" => c}]}
    end)
  end

  defp decode_content(%{"content" => [%{"type" => "tool_use", "name" => name, "input" => input}]}, _raw) do
    %{tool_call: %{name: name, args: input}}
  end

  defp decode_content(_resp, [%{"type" => "text", "text" => text}]), do: %{content: text}
  defp decode_content(_resp, other), do: %{content: inspect(other)}
end
