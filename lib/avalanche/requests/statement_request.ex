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

    %__MODULE__{
      url: Request.server_url(options),
      path: Request.statements_path(),
      headers: Request.build_headers(options, token_type),
      body: build_body(statement, bindings, options),
      token: token,
      options: options
    }
  end

  @doc """
  Runs a statement execution request.

  Returns `{:ok, response}` or `{:error, exception}`.
  """
  def run(%__MODULE__{} = request, opts \\ []) do
    pipeline = build_pipeline(request, opts)
    params = Map.merge(request.body.parameters, request.body.bindings)
    metadata = %{params: params, query: request.body.statement}

    with _ <- Avalanche.Telemetry.start(:query, metadata, %{}),
         {:ok, response} <- Req.Request.run(pipeline),
         {:ok, _result} = success <- handle_response(response),
         _ <- Avalanche.Telemetry.stop(:query, System.monotonic_time(), metadata, %{}) do
      success
    else
      {:error, error} = failure ->
        metadata = Map.put(metadata, :error, error)
        Avalanche.Telemetry.stop(:query, System.monotonic_time(), metadata, %{})
        failure
    end
  end

  defp build_pipeline(request, opts) do
    disable_polling = Keyword.fetch!(opts, :async)
    params = build_params(opts)

    req_options =
      request.options
      |> Keyword.take(Avalanche.available_req_options())
      |> Keyword.merge(
        method: :post,
        base_url: request.url,
        url: Request.statements_path(),
        auth: {:bearer, request.token},
        headers: request.headers,
        params: params,
        json: request.body
      )

    req_options =
      req_options
      |> Keyword.fetch(:retry)
      |> case do
        :error ->
          req_options ++
            [retry: &custom_retry/1, retry_delay: &custom_retry_delay/1, max_retries: 5, retry_log_level: :info]

        _exists ->
          req_options
      end

    poll_options = Keyword.get(request.options, :poll, [])
    decode_data_options = Keyword.get(request.options, :decode_data, [])
    get_partitions_options = Keyword.get(request.options, :get_partitions, [])

    req_options
    |> Req.new()
    |> Steps.Poll.attach(disable_polling, poll_options)
    |> Steps.DecodeData.attach(decode_data_options)
    |> Steps.GetPartitions.attach(get_partitions_options)
  end

  defp build_params(opts) do
    async = Keyword.fetch!(opts, :async)
    request_id = Keyword.get(opts, :request_id)
    retry = Keyword.get(opts, :retry)

    # credo:disable-for-lines:2 Credo.Check.Readability.SinglePipe
    [async: async, requestId: request_id, retry: retry]
    |> Keyword.filter(fn {_key, value} -> !is_nil(value) end)
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
    do: {:ok, %Result{status: :complete, statement_handle: nil, num_rows: 0, rows: []}}

  defp handle_response(%Req.Response{status: 200, body: body}) do
    statement_handle = Map.fetch!(body, "statementHandle")
    data = Map.fetch!(body, "data")

    metadata = Map.fetch!(body, "resultSetMetaData")
    num_rows = Map.fetch!(metadata, "numRows")

    {:ok, %Result{status: :complete, statement_handle: statement_handle, num_rows: num_rows, rows: data}}
  end

  defp handle_response(%Req.Response{status: 202, body: body}) do
    statement_handle = Map.fetch!(body, "statementHandle")

    {:ok, %Result{status: :running, statement_handle: statement_handle}}
  end

  defp handle_response(%Req.Response{status: status} = response)
       when status not in [200, 202] do
    error = Error.http_status(status, error: response.body, headers: response.headers)

    {:error, error}
  end

  defp custom_retry(response_or_exception) do
    case response_or_exception do
      %Req.Response{status: status} when status in [408, 429] or status in 500..599 ->
        true

      %Req.Response{} ->
        false

      # coveralls-ignore-start
      %{__exception__: true} ->
        true
        # coveralls-ignore-stop
    end
  end

  defp custom_retry_delay(0), do: 1000
  defp custom_retry_delay(1), do: 2000
  defp custom_retry_delay(2), do: 2000
  defp custom_retry_delay(_), do: 4000
end
