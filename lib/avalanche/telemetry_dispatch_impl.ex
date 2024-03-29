defmodule Avalanche.Telemetry.TelemetryDispatchImpl do
  @moduledoc """
  Wrapper around `:telemetry`
  """

  @behaviour Avalanche.Telemetry.TelemetryDispatchBehaviour

  @impl true
  def execute(event_details, measurements, meta) do
    # coveralls-ignore-start
    :telemetry.execute(event_details, measurements, meta)
    # coveralls-ignore-stop
  end
end
