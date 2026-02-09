defmodule AiRulesAgent.Transports.OpenAIEmbeddings do
  @moduledoc """
  Minimal OpenAI embeddings wrapper returning vectors for text.
  """

  @endpoint "https://api.openai.com/v1/embeddings"

  def embed(texts, opts) when is_list(texts) do
    model = Keyword.get(opts, :model, "text-embedding-3-small")
    api_key = Keyword.get(opts, :api_key, System.get_env("OPENAI_API_KEY"))
    base_url = Keyword.get(opts, :base_url, @endpoint)
    headers = %{"authorization" => "Bearer #{api_key}", "content-type" => "application/json"}

    body = %{"model" => model, "input" => texts}

    case Req.post(url: base_url, headers: headers, json: body) do
      {:ok, %Req.Response{status: 200, body: %{"data" => data}}} ->
        {:ok, Enum.map(data, fn %{"embedding" => vec} -> vec end)}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
