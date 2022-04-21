defmodule AvalancheIntegrationTest do
  use ExUnit.Case, async: true

  alias Avalanche.TestHelper

  @moduletag integration: true

  describe "run/2 with OAuth token" do
    setup do
      options = TestHelper.test_options()
      [options: options]
    end

    test "returns a Result struct", c do
      assert {:ok, %Avalanche.Result{} = result} = Avalanche.run("select 1;", [], c.options)
      assert result.num_rows == 1
    end
  end

  describe "run/2 with Key Pair token" do
    setup do
      options = TestHelper.test_key_pair_options()
      [options: options]
    end

    test "returns a Result struct", c do
      assert {:ok, %Avalanche.Result{} = result} = Avalanche.run("select 1;", [], c.options)
      assert result.num_rows == 1
    end
  end

  describe "run/2" do
    setup do
      options = TestHelper.test_options()
      [options: options]
    end

    test "allows bind variables", c do
      assert {:ok, %Avalanche.Result{} = result} = Avalanche.run("select ?;", [33], c.options)
      assert result.num_rows == 1
    end

    test "parses result body into list of maps", c do
      assert {:ok, %Avalanche.Result{} = result1} =
               Avalanche.run(
                 "SELECT *, 9 as number FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS LIMIT ?",
                 [2],
                 c.options
               )

      assert result1.num_rows == 2

      assert [
               %{
                 "NUMBER" => 9,
                 "O_CLERK" => "Clerk#000000340",
                 "O_COMMENT" => "ourts are carefully above the slyly final theodolites.",
                 "O_CUSTKEY" => 121_361,
                 "O_ORDERDATE" => ~D[1994-01-24],
                 "O_ORDERKEY" => 1_200_001,
                 "O_ORDERPRIORITY" => "1-URGENT",
                 "O_ORDERSTATUS" => "F",
                 "O_SHIPPRIORITY" => 0,
                 "O_TOTALPRICE" => 60_106
               }
               | _rest
             ] = result1.rows

      assert {:ok, %Avalanche.Result{} = result2} =
               Avalanche.run(
                 "SELECT * FROM SNOWFLAKE_SAMPLE_DATA.WEATHER.DAILY_16_TOTAL LIMIT 1",
                 [],
                 c.options
               )

      assert result2.num_rows == 1

      assert [%{"T" => ~N[2016-09-07 00:38:01.000], "V" => _stuff1}] = result2.rows
    end
  end
end
