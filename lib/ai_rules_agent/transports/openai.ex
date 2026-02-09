defmodule AiRulesAgent.Transports.OpenAI do
  @moduledoc """
  Thin helper that returns an `llm_fun` compatible with `AiRulesAgent.AgentServer`.

  It uses the OpenAI Chat Completions API (or any provider exposing the same schema)
  via `Req`. Intended for quick local runs; callers can swap in their own transport.
  """

  @endpoint "https://api.openai.com/v1/chat/completions"

  @doc """
  Build an `llm_fun`.

  Options:
  * `:model` (required) — model name
  * `:api_key` (default: `System.get_env(\"OPENAI_API_KEY\")`)
  * `:base_url` (optional) — override endpoint (e.g., OpenRouter, Azure)
  * `:headers` (optional) — extra headers (map)
  * `:temperature` (optional) — float
  * `:logprobs` (optional) — passthrough field
  * `:req` (optional) — module implementing `post/1` like `Req`; defaults to `Req`
  """
  def llm_fun(opts) do
    model = Keyword.fetch!(opts, :model)
    api_key = Keyword.get(opts, :api_key, System.get_env("OPENAI_API_KEY"))
    base_url = Keyword.get(opts, :base_url, @endpoint)
    extra_headers = Keyword.get(opts, :headers, %{})
    temperature = Keyword.get(opts, :temperature)
    logprobs = Keyword.get(opts, :logprobs)
    req_mod = Keyword.get(opts, :req, Req)

    fn %{messages: messages} = payload ->
      headers = %{
        "content-type" => "application/json",
        "authorization" => "Bearer #{api_key}"
      }
      |> Map.merge(extra_headers)

      tool_specs =
        payload
        |> Map.get(:tools, [])
        |> Enum.map(fn %{name: name} ->
          %{
            type: "function",
            function: %{
              name: name,
              parameters: %{
                type: "object",
                properties: %{},
                additionalProperties: true
              }
            }
          }
        end)

      body =
        %{
          model: model,
          messages: to_oai_messages(messages),
          tools: if(tool_specs == [], do: nil, else: tool_specs),
          temperature: temperature,
          logprobs: logprobs
        }
        |> Enum.reject(fn {_k, v} -> is_nil(v) end)
        |> Map.new()

      case req_mod.post(url: base_url, headers: headers, json: body) do
        {:ok, %Req.Response{status: 200, body: %{"choices" => [choice | _]}}} ->
          {:ok, decode_choice(choice)}

        {:ok, %Req.Response{status: status, body: body}} ->
          {:error, {:http_error, status, body}}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp to_oai_messages(messages) do
    Enum.map(messages, fn
      %{role: :user, content: c} -> %{role: "user", content: c}
      %{role: :assistant, content: c} -> %{role: "assistant", content: c}
      %{role: :tool, name?: name, content: c} -> %{role: "tool", name: name, content: c}
    end)
  end

  def decode_choice(%{"message" => %{"tool_calls" => [tool | _]} = msg}) do
    tool_call = %{
      name: tool["function"]["name"],
      args: decode_args(tool["function"]["arguments"])
    }

    %{tool_call: tool_call, content: msg["content"]}
  end

  def decode_choice(%{"message" => %{"content" => content}}) do
    %{content: content}
  end

  def decode_choice(other), do: %{content: inspect(other)}

  defp decode_args(args) when is_binary(args) do
    case Jason.decode(args) do
      {:ok, map} -> map
      _ -> %{"raw" => args}
    end
  end

  defp decode_args(other), do: other
end
