defmodule Avalanche.StatementRequest do
  @moduledoc """
  The execute statement request struct.

  Struct fields:

    * `:url` - the HTTP request URL (e.g. https://account-id.snowflakecomputing.com)

    * `:headers` - the HTTP request headers

    * `:body` - the HTTP request body

    * `:token` - the HTTP Bearer authentication token
  """

  use Avalanche.Request

  defstruct [
    :url,
    :path,
    :headers,
    :body,
    :token
  ]

  @type url :: String.t() | URI.t()
  @type body :: map() | nil

  @type t :: %__MODULE__{
          url: url(),
          path: String.t(),
          headers: keyword(),
          body: body(),
          token: String.t()
        }

  @doc """
  Builds a statement execution request to run.
  """
  @spec build(String.t(), list(), keyword()) :: t()
  def build(statement, params, options) do
    bindings = Avalanche.Bindings.encode_params(params)

    {token_type, token} = fetch_token(options)

    %__MODULE__{
      url: server_url(options),
      path: @statements_path,
      headers: build_headers(options, token_type),
      body: build_body(statement, bindings, options),
      token: token
    }
  end

  @doc """
  Runs a statement execution request.

  Returns `{:ok, response}` or `{:error, exception}`.
  """
  def run(%__MODULE__{} = request) do
    pipeline = build_pipeline(request)

    with {:ok, response} <- Req.Request.run(pipeline) do
      handle_response(response)
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

  defp build_pipeline(request) do
    request_id = get_request_id()
    params = [requestId: request_id]

    options = [
      base_url: request.url,
      params: params,
      auth: {:bearer, request.token}
    ]

    :post
    |> Req.Request.build(@statements_path, headers: request.headers, body: {:json, request.body})
    |> Req.Steps.put_default_steps(options)
    |> Req.Request.append_response_steps([
      {Steps.Poll, :poll, [[]]},
      {Steps.DecodeData, :decode_body_data, []},
      {Steps.FetchPartitions, :fetch_partitions, []}
    ])
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

  defp handle_response(%Req.Response{status: 200, body: body}) do
    statement_handle = Map.fetch!(body, "statementHandle")
    data = Map.fetch!(body, "data")

    metadata = Map.fetch!(body, "resultSetMetaData")
    num_rows = Map.fetch!(metadata, "numRows")

    {:ok, %Result{statement_handle: statement_handle, num_rows: num_rows, rows: data}}
  end
end
