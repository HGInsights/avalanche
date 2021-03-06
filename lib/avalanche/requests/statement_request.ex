defmodule Avalanche.StatementRequest do
  @moduledoc """
  The execute statement request struct.

  Struct fields:

    * `:url` - the HTTP request URL (e.g. https://account-id.snowflakecomputing.com)

    * `:headers` - the HTTP request headers

    * `:body` - the HTTP request body

    * `:token` - the HTTP Bearer authentication token

    * `:options` - options to customize HTTP pipeline steps
  """

  alias Avalanche.Error
  alias Avalanche.Request
  alias Avalanche.Result
  alias Avalanche.Steps

  defstruct [
    :url,
    :path,
    :headers,
    :body,
    :token,
    :options
  ]

  @type url :: String.t() | URI.t()
  @type body :: map() | nil

  @type t :: %__MODULE__{
          url: url(),
          path: String.t(),
          headers: keyword(),
          body: body(),
          token: String.t(),
          options: keyword()
        }

  @doc """
  Builds a statement execution request to run.
  """
  @spec build(String.t(), list(), keyword()) :: t()
  def build(statement, params, options) do
    bindings = Avalanche.Bindings.encode_params(params)

    {token_type, token} = Request.fetch_token(options)
    request_options = Request.request_options(options)

    %__MODULE__{
      url: Request.server_url(options),
      path: Request.statements_path(),
      headers: Request.build_headers(options, token_type),
      body: build_body(statement, bindings, options),
      token: token,
      options: request_options
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

  defp build_pipeline(request) do
    request_id = Request.get_request_id()

    req_options =
      request.options
      |> Keyword.take([:finch, :finch_options])
      |> Keyword.merge(
        method: :post,
        base_url: request.url,
        url: Request.statements_path(),
        auth: {:bearer, request.token},
        headers: request.headers,
        params: [requestId: request_id],
        json: request.body
      )

    poll_options = Keyword.get(request.options, :poll_options, [])
    get_partitions_options = Keyword.get(request.options, :get_partitions_options, [])

    req_options
    |> Req.new()
    |> Steps.Poll.attach(poll_options)
    |> Steps.DecodeData.attach()
    |> Steps.GetPartitions.attach(get_partitions_options)
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

  defp handle_response(%Req.Response{status: 200, body: ""}),
    do: {:ok, %Result{num_rows: 0, rows: []}}

  defp handle_response(%Req.Response{status: 200, body: body}) do
    statement_handle = Map.fetch!(body, "statementHandle")
    data = Map.fetch!(body, "data")

    metadata = Map.fetch!(body, "resultSetMetaData")
    num_rows = Map.fetch!(metadata, "numRows")

    {:ok, %Result{statement_handle: statement_handle, num_rows: num_rows, rows: data}}
  end

  defp handle_response(%Req.Response{status: status} = response)
       when status not in [200, 202] do
    error = Error.http_status(status, error: response.body, headers: response.headers)

    {:error, error}
  end
end
