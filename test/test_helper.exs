Vapor.load!([%Vapor.Provider.Dotenv{}])
ExUnit.start(exclude: [skip: true, integration: true])

defmodule Avalanche.TestHelper do
  def test_options(options \\ []) do
    env_options = [
      server: System.fetch_env!("AVALANCHE_SERVER"),
      token: System.fetch_env!("AVALANCHE_TOKEN"),
      warehouse: System.fetch_env!("AVALANCHE_WAREHOUSE"),
      database: System.fetch_env!("AVALANCHE_DATABASE"),
      schema: System.fetch_env!("AVALANCHE_SCHEMA"),
      role: System.fetch_env!("AVALANCHE_ROLE")
    ]

    Keyword.merge(env_options, options)
  end

  def test_key_pair_options(options \\ []) do
    env_options = [
      server: System.fetch_env!("AVALANCHE_SERVER"),
      token: [
        account: System.fetch_env!("AVALANCHE_ACCOUNT"),
        user: System.fetch_env!("AVALANCHE_USER"),
        priv_key: System.fetch_env!("AVALANCHE_PRIV_KEY")
      ],
      warehouse: System.fetch_env!("AVALANCHE_WAREHOUSE"),
      database: System.fetch_env!("AVALANCHE_DATABASE"),
      schema: System.fetch_env!("AVALANCHE_SCHEMA"),
      role: System.fetch_env!("AVALANCHE_ROLE")
    ]

    Keyword.merge(env_options, options)
  end
end
