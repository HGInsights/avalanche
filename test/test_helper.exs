Vapor.load!([%Vapor.Provider.Dotenv{}])

Mox.defmock(JWTBehaviourMock, for: Avalanche.JWTs.JWTBehaviour)
Application.put_env(:avalanche, :jwt_impl, JWTBehaviourMock)

Mox.defmock(TelemetryDispatchBehaviourMock, for: Avalanche.Telemetry.TelemetryDispatchBehaviour)
Application.put_env(:avalanche, :telemetry_dispatch_impl, TelemetryDispatchBehaviourMock)

ExUnit.start(exclude: [:skip, :integration])
