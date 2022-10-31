Vapor.load!([%Vapor.Provider.Dotenv{}])

Mimic.copy(Joken.Signer)
Mox.defmock(TelemetryDispatchBehaviourMock, for: Avalanche.Telemetry.TelemetryDispatchBehaviour)
Application.put_env(:avalanche, :telemetry_dispatch_impl, TelemetryDispatchBehaviourMock)

ExUnit.start(exclude: [:skip, :integration])
