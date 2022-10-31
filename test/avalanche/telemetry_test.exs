defmodule Avalanche.TelemetryTest do
  @moduledoc false

  use ExUnit.Case

  alias Avalanche.Telemetry
  import Mox

  setup :verify_on_exit!

  describe "start/3" do
    test "returns a map with the start time and the telemetry start output" do
      expect(TelemetryDispatchBehaviourMock, :execute, fn event_details, measurements, meta ->
        assert [:avalanche, :an_event, :start] == event_details
        assert %{extra_measurements: "valid", system_time: _} = measurements
        assert %{meta_map: "valid"} == meta

        :ok
      end)

      assert %{start_time: start_time, telemetry_output: :ok} =
               Telemetry.start(:an_event, %{meta_map: "valid"}, %{extra_measurements: "valid"})

      assert is_integer(start_time)
    end
  end

  describe "stop/4" do
    test "returns a map with the end time and the telemetry stop output" do
      expect(TelemetryDispatchBehaviourMock, :execute, fn event_details, measurements, meta ->
        assert [:avalanche, :an_event, :stop] == event_details
        assert %{extra_measurements: "valid", duration: _} = measurements
        assert %{meta_map: "valid"} == meta

        :ok
      end)

      assert %{end_time: end_time, telemetry_output: :ok} =
               Telemetry.stop(:an_event, System.monotonic_time(), %{meta_map: "valid"}, %{extra_measurements: "valid"})

      assert is_integer(end_time)
    end
  end

  describe "exception/7" do
    test "returns a map with the result of a an exception event" do
      expect(TelemetryDispatchBehaviourMock, :execute, fn event_details, measurements, meta ->
        assert [:avalanche, :an_event, :exception] == event_details
        assert %{duration: _} = measurements
        assert %{error: "Something went wrong", kind: :a_bad_kind, stacktrace: []} == meta

        :ok
      end)

      event = :an_event
      start_time = System.monotonic_time()
      kind = :a_bad_kind
      reason = "Something went wrong"
      stack = []
      meta = %{}
      extra_measurements = %{}

      assert %{telemetry_output: :ok} =
               Telemetry.exception(event, start_time, kind, reason, stack, meta, extra_measurements)
    end
  end

  describe "event/3" do
    test "returns a map with the result of a generic telemetry event" do
      expect(TelemetryDispatchBehaviourMock, :execute, fn event_details, measurements, meta ->
        assert [:avalanche, :custom_event] == event_details
        assert %{test: 123} = measurements
        assert %{test: :test} == meta

        :ok
      end)

      assert %{telemetry_output: :ok} = Telemetry.event(:custom_event, %{test: 123}, %{test: :test})
    end
  end
end
