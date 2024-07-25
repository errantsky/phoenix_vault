defmodule OpenAIClient do
  require Logger

  @openai_api_url "https://api.openai.com/v1/embeddings"
  @embedding_model_name "text-embedding-3-small"
  @embedding_max_tokens 8191

  @doc """
  Fetches the embedding for a given text using OpenAI's API.

  ## Parameters

    - text: The input text for which the embedding is to be fetched.
    - openai_api_key: The API key for authenticating with OpenAI. If not provided, it will be fetched from the application environment.

  ## Returns

    - {:ok, embedding}: On success, returns the embedding data.
    - {:error, reason}: On failure, returns the error reason.
  """
  def get_embedding(text, openai_api_key \\ Application.get_env(:phoenix_vault, :openai_api_key)) do
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer #{openai_api_key}"}
    ]
    
    Logger.debug("OpenAIClient get_embedding query: #{text}")
    
    {:ok, encoded_list} = Tiktoken.CL100K.encode(text) 
    truncated_token_list = Enum.take(encoded_list, @embedding_max_tokens)
    
    request_body =
      %{
        input: truncated_token_list,
        model: @embedding_model_name
      }
      |> Jason.encode!()

    Finch.build(:post, @openai_api_url, headers, request_body)
    |> Finch.request(PhoenixVault.Finch)
    |> handle_response()
  end

  # The following params are dropped from the API response:
  # "model" => "text-embedding-3-small",
  # "object" => "list",
  # "usage" => %{"prompt_tokens" => 1, "total_tokens" => 1}
  defp handle_response({:ok, %Finch.Response{status: 200, body: body}}) do
    {:ok, Jason.decode!(body) |> get_in(["data", Access.at(0), "embedding"])}
  end

  defp handle_response({:ok, %Finch.Response{status: status, body: body}}) do
    Logger.error("Failed with status: #{status} and body: #{body}")
    {:error, body}
  end

  defp handle_response({:error, reason}) do
    Logger.error("HTTP request failed: #{inspect(reason)}")
    {:error, reason}
  end
end
