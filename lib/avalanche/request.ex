defmodule Avalanche.Request do
  @moduledoc """
  The request struct.

  Struct fields:

    * `:url` - the HTTP request URL (e.g. https://account-id.snowflakecomputing.com)

    * `:headers` - the HTTP request headers

    * `:body` - the HTTP request body

    * `:token` - the HTTP Bearer authentication token
  """

  alias Avalanche.Error
  alias Avalanche.Result

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
      result_from_response(response)
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

    options = [
      base_url: request.url,
      params: params,
      auth: {:bearer, request.token},
      retry: [delay: 100, max_retries: 3]
    ]

    :post
    |> Req.Request.build(@statements_path, headers: request.headers, body: {:json, request.body})
    |> Req.Steps.put_default_steps(options)
    |> Req.Request.append_response_steps([{Avalanche.Steps, :decode_body_data, []}])
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
      parameters: %{
        "TIME_OUTPUT_FORMAT" => "HH24:MI:SS",
        "TIMESTAMP_OUTPUT_FORMAT" => "YYYY-MM-DD HH24:MI:SS.FFTZH:TZM",
        "TIMESTAMP_NTZ_OUTPUT_FORMAT" => "YYYY-MM-DD HH24:MI:SS.FF3"
      },
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

  defp result_from_response(%Req.Response{status: 200, body: body}) do
    metadata = Map.fetch!(body, "resultSetMetaData")
    num_rows = Map.fetch!(metadata, "numRows")
    data = Map.fetch!(body, "data")

    {:ok, %Result{num_rows: num_rows, rows: data}}
  end

  defp result_from_response(%Req.Response{} = response) do
    error = Error.http_status(response.status, body: response.body, headers: response.headers)

    {:error, error}
  end
end