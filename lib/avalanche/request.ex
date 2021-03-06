defmodule Avalanche.Request do
  @moduledoc """
  Request helpers.
  """

  @user_agent "avalanche/#{Mix.Project.config()[:version]}"
  @statements_path "/api/v2/statements"

  def statements_path, do: @statements_path

  def build_headers(options, token_type) do
    user_agent = Keyword.get(options, :user_agent, @user_agent)

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
    Keyword.take(options, [:finch, :finch_options, :poll_options, :get_partitions_options])
  end

  defp url_with_sheme(url) do
    if url_without_scheme?(url), do: "https://" <> url, else: url
  end

  defp url_without_scheme?(url) when is_binary(url) do
    is_nil(URI.parse(url).scheme)
  end
end
