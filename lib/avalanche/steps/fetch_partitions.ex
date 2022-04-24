defmodule Avalanche.Steps.FetchPartitions do
  @moduledoc """
  A custom `Req` pipeline step to retrieve all the partitons of data from a statement execution.
  """

  require Logger

  @doc """
  Fetches partitioned data per the `resultSetMetaData`.

  https://docs.snowflake.com/en/developer-guide/sql-api/reference.html#label-sql-api-reference-resultset-resultsetmetadata
  """
  def fetch_partitions(request_response)

  def fetch_partitions({request, %{body: ""} = response}) do
    {request, response}
  end

  def fetch_partitions(
        {request, %{status: 200, body: %{"resultSetMetaData" => metadata} = body} = response}
      ) do
    path = Map.fetch!(body, "statementStatusUrl")
    data = Map.fetch!(body, "data")

    row_types = Map.fetch!(metadata, "rowType")
    partitions = Map.fetch!(metadata, "partitionInfo")

    partition_data =
      case partitions do
        [_head | rest] ->
          requests =
            rest
            |> Enum.with_index(1)
            |> Enum.map(fn {_info, partition} ->
              build_status_request(request, path, partition, row_types)
            end)

          Task.Supervisor.async_stream_nolink(
            Avalanche.TaskSupervisor,
            requests,
            fn request -> Req.Request.run!(request) end,
            ordered: true,
            timeout: :timer.seconds(120),
            on_timeout: :kill_task
          )
          |> Stream.filter(fn
            {:ok, _result} -> true
            {:exit, _reason} -> false
          end)
          |> Stream.map(fn {:ok, %Req.Response{} = response} ->
            get_in(response.body, ["data"])
          end)
          |> Enum.to_list()
          |> List.flatten()

        _ ->
          []
      end

    rows = List.flatten(data, partition_data)

    {request, %Req.Response{response | body: Map.put(body, "data", rows)}}
  end

  def fetch_partitions(request_response), do: request_response

  # reuse current request and turn it into a `StatusRequest`
  defp build_status_request(%Req.Request{} = request, path, partition, row_types) do
    request
    |> Map.put(:method, :get)
    |> Map.put(:body, "")
    |> Map.put(:url, URI.parse(path))
    |> Req.Request.put_private(:avalanche_row_types, row_types)
    |> Req.Request.append_request_steps([{Req.Steps, :put_params, [[partition: partition]]}])
  end
end
