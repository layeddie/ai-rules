defmodule AiRulesAgent.Transports.OpenRouter do
  @moduledoc """
  Build an `llm_fun` for OpenRouter (OpenAI-compatible) via Req.
  """

  @endpoint "https://openrouter.ai/api/v1/chat/completions"

  def llm_fun(opts) do
    model = Keyword.fetch!(opts, :model)
    api_key = Keyword.get(opts, :api_key, System.get_env("OPENROUTER_API_KEY"))
    base_url = Keyword.get(opts, :base_url, @endpoint)
    extra_headers = Keyword.get(opts, :headers, %{})
    req_mod = Keyword.get(opts, :req, Req)

    fn %{messages: messages} = payload ->
      headers =
        %{
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
              parameters: %{"type" => "object", "properties" => %{}, "additionalProperties" => true}
            }
          }
        end)

      body =
        %{
          model: model,
          messages: to_oai_messages(messages),
          tools: if(tool_specs == [], do: nil, else: tool_specs)
        }
        |> Enum.reject(fn {_k, v} -> is_nil(v) end)
        |> Map.new()

        case req_mod.post(url: base_url, headers: headers, json: body) do
          {:ok, %Req.Response{status: 200, body: %{"choices" => [choice | _]}}} ->
            {:ok, AiRulesAgent.Transports.OpenAI.decode_choice(choice)}

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
end
