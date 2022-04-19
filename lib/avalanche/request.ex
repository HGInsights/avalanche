defmodule Avalanche.Request do
  @moduledoc """
  The request struct.

  Struct fields:

    * `:url` - the HTTP request URL (e.g. https://account-id.snowflakecomputing.com)

    * `:headers` - the HTTP request headers

    * `:body` - the HTTP request body

    * `:token` - the HTTP Bearer authentication token
  """

  @statements_path "/api/v2/statements"

  defstruct [
    :url,
    :headers,
    :body,
    :token
  ]

  @type url :: String.t() | URI.t()
  @type body :: map()

  @type t :: %__MODULE__{
          url: url(),
          headers: keyword(),
          body: body(),
          token: String.t()
        }

  @doc """
  Builds a request to run.
  """
  @spec build(String.t(), list(), keyword()) :: Avalanche.Request.t()
  def build(statement, params, options) do
    bindings = Avalanche.Bindings.encode_params(params)

    token_opts = Keyword.fetch!(options, :token)
    {token_type, token} = Avalanche.TokenCache.fetch_token(token_opts)

    %__MODULE__{
      url: server_url(options),
      headers: build_headers(options, token_type),
      body: build_body(statement, bindings, options),
      token: token
    }
  end

  @doc """
  Runs a request.

  Returns `{:ok, response}` or `{:error, exception}`.
  """
  def run(%__MODULE__{} = request) do
    pipeline = req_build_pipeline(request)

    with {:ok, response} <- Req.Request.run(pipeline) do
      {:ok,
       %Avalanche.Response{
         body: response.body,
         headers: response.headers,
         status: response.status
       }}
    end
  end

  @doc """
  Runs a request and returns a response or raises an error.

  See `run/1` for more information.
  """
  def run!(%__MODULE__{} = request) do
    case run(request) do
      {:ok, response} -> response
      {:error, exception} -> raise exception
    end
  end

  defp req_build_pipeline(request) do
    request_id = get_request_id()
    params = [requestId: request_id]

    options = [base_url: request.url, params: params, auth: {:bearer, request.token}]

    :post
    |> Req.Request.build(@statements_path, headers: request.headers, body: {:json, request.body})
    |> Req.Steps.put_default_steps(options)
  end

  defp build_headers(options, token_type) do
    user_agent = Keyword.get(options, :user_agent, "avalanche/#{Mix.Project.config()[:version]}")

    [
      accept: "application/json",
      user_agent: user_agent,
      "X-Snowflake-Authorization-Token-Type": token_type
    ]
  end

  defp build_body(statement, bindings, options) do
    %{
      warehouse: Keyword.fetch!(options, :warehouse),
      database: Keyword.fetch!(options, :database),
      schema: Keyword.fetch!(options, :schema),
      role: Keyword.fetch!(options, :role),
      timeout: Keyword.fetch!(options, :timeout),
      statement: statement,
      bindings: bindings
    }
  end

  defp server_url(options) do
    options |> Keyword.fetch!(:server) |> url_with_sheme()
  end

  defp url_with_sheme(url) do
    if url_without_scheme?(url), do: "https://" <> url, else: url
  end

  defp url_without_scheme?(url) when is_binary(url) do
    is_nil(URI.parse(url).scheme)
  end

  defp get_request_id, do: UUID.uuid4()
end
