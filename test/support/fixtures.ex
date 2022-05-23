defmodule Avalanche.TestFixtures do
  @moduledoc false

  def test_options(options \\ []) do
    sf_token = System.get_env("SNOWFLAKE_OAUTH_ACCESS_TOKEN", "noop")
    token = System.get_env("AVALANCHE_TOKEN", sf_token)

    env_options = [
      server: System.fetch_env!("AVALANCHE_SERVER"),
      token: token,
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

  def result_set_fixture(attrs \\ %{}) do
    defaults = %{
      "resultSetMetaData" => %{
        "numRows" => 3,
        "format" => "jsonv2",
        "rowType" => [
          %{
            "name" => "COLUMN1",
            "type" => "fixed"
          },
          %{
            "name" => "COLUMN2",
            "type" => "text"
          }
        ],
        "partitionInfo" => [
          %{
            "rowCount" => 3,
            "uncompressedSize" => 1234
          }
        ]
      },
      "data" => [["0", "zero"], ["1", "one"], ["2", "two"]],
      "code" => "090001",
      "statementStatusUrl" => "/api/v2/statements/e4ce975e-f7ff-4b5e-b15e-bf25f59371ae",
      "sqlState" => "00000",
      "statementHandle" => "e4ce975e-f7ff-4b5e-b15e-bf25f59371ae",
      "message" => "Statement executed successfully.",
      "createdOn" => 1_620_151_693_299
    }

    deep_merge(defaults, attrs)
  end

  @doc """
  Performs recursive merge of two maps.

  Example:
      iex> map1 = %{a: 1, b: 2, c: %{d: 3}}
      iex> map2 = %{a: 4, c: %{e: 5}, f: 6}
      iex> deep_merge(map1, map2)
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
