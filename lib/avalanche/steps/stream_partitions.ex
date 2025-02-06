defmodule Avalanche.Steps.StreamPartitions do
  @moduledoc """
  A custom `Req` pipeline step to stream partitions of data from a statement execution.

  This module implements streaming of partitioned data responses from Snowflake using the SQL API.
  It ensures partitions are retrieved and processed in the correct order.

  See: https://docs.snowflake.com/en/developer-guide/sql-api/handling-responses
  """

  require Logger

  @doc """
  Attach the streaming step to a Req pipeline.

  ## Options

    * `:max_concurrency` - sets the maximum number of tasks to run at the same time.
      Defaults to `System.schedulers_online/0`.

    * `:timeout` - the maximum amount of time to wait (in milliseconds) for each partition.
      Defaults to 2 minutes.
  """
  def attach(%Req.Request{} = request, options \\ []) do
    request
    |> Req.Request.register_options([:max_concurrency, :timeout, :params])
    |> Req.Request.merge_options(options)
    |> Req.Request.append_response_steps(stream_partitions: &stream_partitions/1)
  end

  def stream_partitions(request_response)

  def stream_partitions({request, %{status: 200, body: %{"resultSetMetaData" => metadata} = body} = response}) do
    options = request.options || %{}
    max_concurrency = Map.get(options, :max_concurrency, System.schedulers_online())
    timeout = Map.get(options, :timeout, 120_000)  # Default to 2 minutes

    path = Map.get(body, "statementStatusUrl")
    data = Map.get(body, "data", [])

    row_types = Map.get(metadata, "rowType", [])
    partitions = Map.get(metadata, "partitionInfo", [])

    partition_stream =
      case {path, partitions} do
        {nil, _} ->
          []

        {_, []} ->
          []

        {_, "0"} ->
          []

        {path, [_head | rest]} when is_binary(path) ->
          rest
          |> Stream.with_index(1)
          |> Stream.map(fn {_info, partition} ->
            build_status_request(request, path, partition, row_types)
          end)
          |> Task.async_stream(
            fn req -> 
              Req.Request.run_request(req)
            end,
            ordered: true,
            max_concurrency: max_concurrency,
            timeout: timeout,
            on_timeout: :kill_task
          )
          |> Stream.map(fn
            {:ok, {:ok, value}} -> value
            {:ok, error} -> error_response(error)
            {:exit, reason} -> error_response(reason)
          end)
          |> Stream.map(&handle_partition_response/1)
          |> Stream.filter(&(&1.status == 200))
          |> Stream.flat_map(&Map.get(&1.body, "data", []))
      end

    # Create a stream of the initial data and partition data
    stream = Stream.concat(Stream.map([data], & &1), partition_stream)
    {request, %{response | body: Map.put(body, "data", stream)}}
  end

  def stream_partitions({request, %{status: 200, body: ""} = response}) do
    {request, response}
  end

  def stream_partitions({request, %{status: 202} = response}) do
    {request, response}
  end

  def stream_partitions({request, %{status: status} = response}) when status >= 400 do
    {request, response}
  end

  def stream_partitions(request_response), do: request_response

  # Private helpers

  defp build_status_request(request, path, partition, row_types) do
    # Start with a new request but copy over the relevant options from the original
    # Handle cases where headers might be nil
    headers = request.headers || %{}
    options = request.options || %{}

    Req.new(
      method: :get,
      url: path,
      params: [partition: partition],
      auth: options[:auth],  # Get auth from options
      headers: headers,
      receive_timeout: options[:timeout]  # Map our timeout to Req's receive_timeout
    )
    |> Req.Request.put_private(:avalanche_row_types, row_types)
  end

  defp handle_partition_response(response) do
    case response do
      {:ok, {_request, %Req.Response{} = response}} ->
        response

      {:ok, {_request, exception}} ->
        error_response(exception)

      {:exit, reason} ->
        error_response(reason)

      other ->
        error_response(other)
    end
  end

  defp error_response(reason) do
    %{status: 500, body: %{"message" => inspect(reason)}}
  end
end
