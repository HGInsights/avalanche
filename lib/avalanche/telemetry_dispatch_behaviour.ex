defmodule Avalanche.Telemetry.TelemetryDispatchBehaviour do
  @doc """
  Dispatches a telemetry event
  """
  @callback execute(list(), map(), map()) :: atom()
end
