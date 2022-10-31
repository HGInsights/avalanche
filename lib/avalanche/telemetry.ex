defmodule Avalanche.Telemetry do
  @moduledoc """
  Telemetry integration.

  Unless specified, all time's are in `:native` units.

  Avalanche executes the following events:

  ### Query Start

  `[:avalanche, :query, :start]` - Executed at the start of each query sent to Snowflake.

  #### Measurements

    * `:system_time` - The time the query started

  #### Metadata:

    * `:query` - The query sent to the database as a string
    * `:params` - The query parameters

  ### Query Stop

  `[:avalanche, :query, :stop]` - Executed at the end of each query sent to Snowflake.

  #### Measurements

    * `:duration` - The time spent executing the query

  #### Metadata:

    * `:query` - The query sent to the database as a string
    * `:params` - The query parameters
    * `:result` - The query result (selected, updated)
    * `:num_rows` - The number of rows effected by the query
    * `:error` - Present if any error occurred while processing the query. (optional)

  ### Query Exception

  `[:avalanche, :query, :exception]` - Executed if executing a query throws an exception.

  #### Measurements

    * `:duration` - The time spent executing the query

  #### Metadata

    * `:kind` - The type of exception.
    * `:error` - Error description or error data.
    * `:stacktrace` - The stacktrace
  """

  alias Avalanche.Telemetry.TelemetryDispatchImpl

  @doc "Emits a `start` telemetry event"
  @spec start(atom(), map(), map()) :: map()
  def start(event, meta \\ %{}, extra_measurements \\ %{}) do
    start_time = System.monotonic_time()

    telemetry_output =
      telemetry_dispatch_impl().execute(
        [:avalanche, event, :start],
        Map.merge(extra_measurements, %{system_time: System.system_time()}),
        meta
      )

    %{start_time: start_time, telemetry_output: telemetry_output}
  end

  @doc "Emits a stop event"
  @spec stop(atom(), number(), map(), map()) :: map()
  def stop(event, start_time, meta \\ %{}, extra_measurements \\ %{}) do
    end_time = System.monotonic_time()

    measurements = Map.merge(extra_measurements, %{duration: end_time - start_time})

    telemetry_output =
      telemetry_dispatch_impl().execute(
        [:avalanche, event, :stop],
        measurements,
        meta
      )

    %{end_time: end_time, telemetry_output: telemetry_output}
  end

  @doc false
  @spec exception(atom(), number(), any(), any(), any(), map(), map()) :: map()
  def exception(
        event,
        start_time,
        kind,
        reason,
        stack,
        meta \\ %{},
        extra_measurements \\ %{}
      ) do
    end_time = System.monotonic_time()

    measurements = Map.merge(extra_measurements, %{duration: end_time - start_time})

    meta =
      meta
      |> Map.put(:kind, kind)
      |> Map.put(:error, reason)
      |> Map.put(:stacktrace, stack)

    telemetry_output = telemetry_dispatch_impl().execute([:avalanche, event, :exception], measurements, meta)
    %{telemetry_output: telemetry_output}
  end

  @doc "Used for reporting generic events"
  @spec event(atom(), number() | map(), map()) :: map()
  def event(event, measurements, meta) do
    telemetry_output = telemetry_dispatch_impl().execute([:avalanche, event], measurements, meta)
    %{telemetry_output: telemetry_output}
  end

  def telemetry_dispatch_impl() do
    Application.get_env(:avalanche, :telemetry_dispatch_impl, TelemetryDispatchImpl)
  end
end
