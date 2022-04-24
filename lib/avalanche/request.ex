defmodule Avalanche.Request do
  @moduledoc """
  Request helpers.

  `use Avalanche.Request`
  """

  defmacro __using__(_) do
    quote do
      alias Avalanche.Error
      alias Avalanche.Result
      alias Avalanche.Steps

      @statements_path "/api/v2/statements"

      defdelegate build_headers(options, token_type), to: Avalanche.Request
      defdelegate fetch_token(options), to: Avalanche.Request
      defdelegate get_request_id, to: Avalanche.Request
      defdelegate server_url(options), to: Avalanche.Request
      defdelegate request_options(options), to: Avalanche.Request

      defp handle_response(%{status: status} = response)
           when status not in [200, 202] do
        error = Error.http_status(status, error: response.body, headers: response.headers)

        {:error, error}
      end

      defp handle_response({_request, %{status: status} = response})
           when status not in [200, 202] do
        error = Error.http_status(status, error: response.body, headers: response.headers)

        {:error, error}
      end
    end
  end

  def build_headers(options, token_type) do
    user_agent = Keyword.get(options, :user_agent, "avalanche/#{Mix.Project.config()[:version]}")

    [
      accept: "application/json",
      user_agent: user_agent,
      "X-Snowflake-Authorization-Token-Type": token_type
    ]
  end

  def fetch_token(options) do
    token_opts = Keyword.fetch!(options, :token)
    Avalanche.TokenCache.fetch_token(token_opts)
  end

  def get_request_id, do: UUID.uuid4()

  def server_url(options) do
    options |> Keyword.fetch!(:server) |> url_with_sheme()
  end

  def request_options(options) do
    Keyword.take(options, [:finch, :finch_options, :poll_options, :fetch_partitions_options])
  end

  defp url_with_sheme(url) do
    if url_without_scheme?(url), do: "https://" <> url, else: url
  end

  defp url_without_scheme?(url) when is_binary(url) do
    is_nil(URI.parse(url).scheme)
  end
end
