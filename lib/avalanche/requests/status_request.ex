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
  """

  use Avalanche.Request

  defstruct [
    :url,
    :path,
    :headers,
    :token,
    :statement_handle,
    :row_types
  ]

  @type url :: String.t() | URI.t()
  @type row_types :: list(map()) | nil

  @type t :: %__MODULE__{
          url: url(),
          path: String.t(),
          headers: keyword(),
          token: String.t(),
          statement_handle: String.t(),
          row_types: row_types()
        }

  @doc """
  Builds a query status request to run.
  """
  @spec build(String.t(), row_types(), keyword()) :: t()
  def build(statement_handle, row_types \\ nil, options) do
    {token_type, token} = fetch_token(options)

    %__MODULE__{
      url: server_url(options),
      path: @statements_path <> "/#{statement_handle}",
      headers: build_headers(options, token_type),
      token: token,
      statement_handle: statement_handle,
      row_types: row_types
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
    options = [
      base_url: request.url,
      params: [partition: partition],
      auth: {:bearer, request.token},
      retry: [delay: 100, max_retries: 3]
    ]

    :get
    |> Req.Request.build(request.path, headers: request.headers)
    |> Req.Request.put_private(:avalanche_row_types, request.row_types)
    |> Req.Steps.put_default_steps(options)
    |> Req.Request.append_response_steps([{Steps.DecodeData, :decode_body_data, []}])
  end

  defp handle_response({request, %Req.Response{status: 200, body: body}}) do
    data = Map.fetch!(body, "data")

    {:ok, %Result{statement_handle: request.statement_handle, rows: data}}
  end
end
