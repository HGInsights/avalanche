defmodule Avalanche.StatusRequest do
  @moduledoc """
  The check query status request struct.

  Struct fields:

    * `:url` - the HTTP request URL (e.g. https://account-id.snowflakecomputing.com)

    * `:path` - the HTTP request path.

    * `:headers` - the HTTP request headers.

    * `:body` - the HTTP request body.

    * `:token` - the HTTP Bearer authentication token.

    * `:row_types` - an array of objects that describe the columns in the set of results. used for decoding.

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
    :token,
    :statement_handle,
    :row_types,
    :options
  ]

  @type url :: String.t() | URI.t()
  @type row_types :: list(map()) | nil

  @type t :: %__MODULE__{
          url: url(),
          path: String.t(),
          headers: keyword(),
          token: String.t(),
          statement_handle: String.t(),
          row_types: row_types(),
          options: keyword()
        }

  @doc """
  Builds a query status request to run.
  """
  @spec build(String.t(), row_types(), keyword()) :: t()
  def build(statement_handle, row_types \\ nil, options) do
    {token_type, token} = Request.fetch_token(options)
    request_options = Request.request_options(options)

    %__MODULE__{
      url: Request.server_url(options),
      path: Request.statements_path() <> "/#{statement_handle}",
      headers: Request.build_headers(options, token_type),
      token: token,
      statement_handle: statement_handle,
      row_types: row_types,
      options: request_options
    }
  end

  @doc """
  Runs a query status request.

  Returns `{:ok, response}` or `{:error, exception}`.
  """
  def run(%__MODULE__{} = request, async \\ false, partition \\ 0) do
    pipeline = build_pipeline(request, async, partition)

    with {:ok, response} <- Req.Request.run(pipeline) do
      handle_response({request, response})
    end
  end

  defp build_pipeline(request, async, partition) do
    req_options =
      request.options
      |> Keyword.take([:finch, :pool_timeout, :receive_timeout])
      |> Keyword.merge(
        method: :get,
        base_url: request.url,
        url: request.path,
        auth: {:bearer, request.token},
        headers: request.headers,
        params: [partition: partition]
      )

    poll_options = Keyword.get(request.options, :poll_options, [])
    get_partitions_options = Keyword.get(request.options, :get_partitions_options, [])

    req_options
    |> Req.new()
    |> Req.Request.put_private(:avalanche_row_types, request.row_types)
    |> Steps.Poll.attach(async, poll_options)
    |> Steps.DecodeData.attach()
    |> Steps.GetPartitions.attach(get_partitions_options)
  end

  defp handle_response({request, %Req.Response{status: 200, body: body}}) do
    data = Map.fetch!(body, "data")

    {:ok, %Result{statement_handle: request.statement_handle, num_rows: length(data), rows: data}}
  end

  defp handle_response({_request, %Req.Response{status: 202, body: body}}) do
    statement_handle = Map.fetch!(body, "statementHandle")

    {:ok, %Result{statement_handle: statement_handle}}
  end

  defp handle_response({_request, %Req.Response{status: status} = response})
       when status not in [200, 202] do
    error = Error.http_status(status, error: response.body, headers: response.headers)

    {:error, error}
  end
end
