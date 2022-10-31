defmodule Avalanche.Telemetry.TelemetryDispatchBehaviour do
  @doc """
  Dispatches a telemetry event
  """
  @callback execute(keyword(), map(), map()) :: :ok
end
