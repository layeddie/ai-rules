defmodule AiRulesAgent.Transports.OpenAIImages do
  @moduledoc """
  Minimal OpenAI images wrapper (create image from prompt).
  """

  @endpoint "https://api.openai.com/v1/images/generations"

  def generate(prompt, opts) do
    model = Keyword.get(opts, :model, "gpt-image-1")
    size = Keyword.get(opts, :size, "1024x1024")
    api_key = Keyword.get(opts, :api_key, System.get_env("OPENAI_API_KEY"))
    base_url = Keyword.get(opts, :base_url, @endpoint)
    headers = %{"authorization" => "Bearer #{api_key}", "content-type" => "application/json"}

    body = %{"model" => model, "prompt" => prompt, "size" => size}

    case Req.post(url: base_url, headers: headers, json: body) do
      {:ok, %Req.Response{status: 200, body: %{"data" => [%{"url" => url} | _]}}} ->
        {:ok, url}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
