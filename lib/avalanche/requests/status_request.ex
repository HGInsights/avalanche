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

  use Avalanche.Request

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
    {token_type, token} = fetch_token(options)
    request_options = request_options(options)

    %__MODULE__{
      url: server_url(options),
      path: @statements_path <> "/#{statement_handle}",
      headers: build_headers(options, token_type),
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
  def run(%__MODULE__{} = request, partition \\ 0) do
    pipeline = build_pipeline(request, partition)

    with {:ok, response} <- Req.Request.run(pipeline) do
      handle_response({request, response})
    end
  end

  defp build_pipeline(request, partition) do
    req_options =
      request.options
      |> Keyword.take([:finch, :finch_options])
      |> Keyword.merge(headers: request.headers)

    req_step_options = [
      base_url: request.url,
      params: [partition: partition],
      auth: {:bearer, request.token}
    ]

    poll = Keyword.get(request.options, :poll_options, [])
    fetch_partitions = Keyword.get(request.options, :fetch_partitions_options, [])

    :get
    |> Req.Request.build(request.path, req_options)
    |> Req.Request.put_private(:avalanche_row_types, request.row_types)
    |> Req.Steps.put_default_steps(req_step_options)
    |> Req.Request.append_response_steps([
      {Steps.Poll, :poll, [poll]},
      {Steps.DecodeData, :decode_body_data, []},
      {Steps.FetchPartitions, :fetch_partitions, [fetch_partitions]}
    ])
  end

  defp handle_response({request, %Req.Response{status: 200, body: body}}) do
    data = Map.fetch!(body, "data")

    {:ok, %Result{statement_handle: request.statement_handle, num_rows: length(data), rows: data}}
  end
end
