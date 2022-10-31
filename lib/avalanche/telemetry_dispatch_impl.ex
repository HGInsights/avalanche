defmodule Avalanche.Telemetry.TelemetryDispatchImpl do
  @moduledoc """
  Wrapper around `:telemetry`
  """

  @behaviour Avalanche.Telemetry.TelemetryDispatchBehaviour

  @impl Avalanche.Telemetry.TelemetryDispatchBehaviour
  def execute(event_details, measurements, meta) do
    :telemetry.execute(event_details, measurements, meta)
  end
end
