Vapor.load!([%Vapor.Provider.Dotenv{}])

Mimic.copy(Joken.Signer)

ExUnit.start(exclude: [skip: true, integration: true])
