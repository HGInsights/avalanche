Vapor.load!([%Vapor.Provider.Dotenv{}])
ExUnit.start(exclude: [skip: true, integration: true])

defmodule Avalanche.TestHelper do
  def test_options(options \\ []) do
    env_options = [
      server: System.fetch_env!("AVALANCHE_SERVER"),
      token: System.get_env("AVALANCHE_TOKEN") || System.get_env("SNOWFLAKE_OAUTH_ACCESS_TOKEN"),
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

  @doc """
  Performs recursive merge of two maps.

  Example:
      iex> map1 = %{a: 1, b: 2, c: %{d: 3}}
      iex> map2 = %{a: 4, c: %{e: 5}, f: 6}
      iex> TestHelper.deep_merge(map1, map2)
      %{a: 4, b: 2, c: %{d: 3, e: 5}, f: 6}
  """
  @spec deep_merge(map, map) :: map
  def deep_merge(left, right), do: Map.merge(left, right, &deep_resolve/3)

  # Key exists in both maps, and both values are maps as well.
  # These can be merged recursively.
  defp deep_resolve(_key, %{} = left, %{} = right), do: deep_merge(left, right)

  # Key exists in both maps, but at least one of the values is
  # NOT a map. We fall back to standard merge behavior, preferring
  # the value on the right.
  defp deep_resolve(_key, _left, right), do: right
end
