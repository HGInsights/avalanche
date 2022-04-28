defmodule Avalanche.Steps.GetPartitions do
  @moduledoc """
  A custom `Req` pipeline step to retrieve all the partitons of data from a statement execution.
  """

  require Logger

  @doc """
  Get partitioned data per the `resultSetMetaData`.

  https://docs.snowflake.com/en/developer-guide/sql-api/reference.html#label-sql-api-reference-resultset-resultsetmetadata

  ## Options

    * `:max_concurrency` - sets the maximum number of tasks to run at the same time.
      Defaults to `System.schedulers_online/0`.

    * `:timeout` - the maximum amount of time to wait (in milliseconds). Defaults to 2 minutes.
  """
  def get_partitions(request_response, options)

  def get_partitions({request, %{body: ""} = response}, _options) do
    {request, response}
  end

  def get_partitions(
        {request, %{status: 200, body: %{"resultSetMetaData" => metadata} = body} = response},
        options
      ) do
    max_concurrency = Keyword.get(options, :max_concurrency, System.schedulers_online())
    timeout = Keyword.get(options, :timeout, :timer.minutes(2))

    path = Map.fetch!(body, "statementStatusUrl")
    data = Map.fetch!(body, "data")

    row_types = Map.fetch!(metadata, "rowType")
    partitions = Map.fetch!(metadata, "partitionInfo")

    partition_responses =
      case partitions do
        [_head | rest] ->
          requests =
            rest
            |> Enum.with_index(1)
            |> Enum.map(fn {_info, partition} ->
              build_status_request(request, path, partition, row_types)
            end)

          Logger.debug(["Avalanche.get_partitions: #{length(requests)}"])

          Task.Supervisor.async_stream_nolink(
            Avalanche.TaskSupervisor,
            requests,
            fn request -> Req.Request.run(request) end,
            max_concurrency: max_concurrency,
            ordered: true,
            timeout: timeout,
            on_timeout: :kill_task
          )
          |> Stream.map(&handle_partition_response/1)
          |> Enum.to_list()

        _ ->
          []
      end

    {request, reduce_responses(response, data, partition_responses)}
  end

  def get_partitions(request_response, _options), do: request_response

  # reuse current request and turn it into a `StatusRequest`
  defp build_status_request(%Req.Request{} = request, path, partition, row_types) do
    request
    |> Map.put(:method, :get)
    |> Map.put(:body, "")
    |> Map.put(:url, URI.parse(path))
    |> Req.Request.put_private(:avalanche_row_types, row_types)
    |> Req.Request.append_request_steps([{Req.Steps, :put_params, [[partition: partition]]}])
  end

  defp handle_partition_response(response) do
    case response do
      {:ok, {:ok, response}} -> response
      {:ok, {:error, error}} -> error_response(error)
      {:exit, reason} -> error_response(reason)
    end
  end

  defp error_response(error) do
    error_msg =
      case error do
        %{__exception__: true} = exception -> Exception.message(exception)
        _ -> error
      end

    Logger.error(["Avalanche.get_partitions failed.", error_msg])

    %{status: 500, body: nil}
  end

  defp reduce_responses(response, data, partition_responses) do
    if Enum.all?(partition_responses, &success?/1) do
      partition_data =
        Enum.map(partition_responses, fn %{body: body} -> Map.fetch!(body, "data") end)

      rows = List.flatten([data | partition_data])

      %Req.Response{response | body: Map.put(response.body, "data", rows)}
    else
      %Req.Response{response | status: 408, body: %{message: "Fetching all partitions failed."}}
    end
  end

  defp success?(%{status: 200}), do: true
  defp success?(%{status: _other}), do: false
end
