defmodule AiRulesAgent.Transports.OpenAIAudio do
  @moduledoc """
  Minimal OpenAI audio wrappers: text-to-speech (speech) and speech-to-text (whisper).
  """

  @speech_endpoint "https://api.openai.com/v1/audio/speech"
  @transcribe_endpoint "https://api.openai.com/v1/audio/transcriptions"

  def speech(text, opts) do
    model = Keyword.get(opts, :model, "gpt-4o-mini-tts")
    voice = Keyword.get(opts, :voice, "alloy")
    api_key = Keyword.get(opts, :api_key, System.get_env("OPENAI_API_KEY"))
    base_url = Keyword.get(opts, :base_url, @speech_endpoint)
    headers = %{"authorization" => "Bearer #{api_key}", "content-type" => "application/json"}

    body = %{"model" => model, "input" => text, "voice" => voice}

    case Req.post(url: base_url, headers: headers, json: body) do
      {:ok, %Req.Response{status: 200, body: audio}} -> {:ok, audio}
      {:ok, %Req.Response{status: status, body: body}} -> {:error, {:http_error, status, body}}
      {:error, reason} -> {:error, reason}
    end
  end

  def transcribe(file_path, opts) do
    model = Keyword.get(opts, :model, "whisper-1")
    api_key = Keyword.get(opts, :api_key, System.get_env("OPENAI_API_KEY"))
    base_url = Keyword.get(opts, :base_url, @transcribe_endpoint)
    headers = %{"authorization" => "Bearer #{api_key}"}

    multipart = {:multipart, [{"model", model}, {:file, file_path}]}

    case Req.post(url: base_url, headers: headers, body: multipart) do
      {:ok, %Req.Response{status: 200, body: %{"text" => text}}} -> {:ok, text}
      {:ok, %Req.Response{status: status, body: body}} -> {:error, {:http_error, status, body}}
      {:error, reason} -> {:error, reason}
    end
  end
end
