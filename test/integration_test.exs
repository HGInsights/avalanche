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
                 "SELECT *, 9 as number FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS ORDER BY O_ORDERKEY LIMIT ?",
                 [2],
                 c.options
               )

      assert result1.num_rows == 2

      assert [
               %{
                 "NUMBER" => 9,
                 "O_CLERK" => "Clerk#000000951",
                 "O_COMMENT" => "nstructions sleep furiously among ",
                 "O_CUSTKEY" => 36_901,
                 "O_ORDERDATE" => ~D[1996-01-02],
                 "O_ORDERKEY" => 1,
                 "O_ORDERPRIORITY" => "5-LOW",
                 "O_ORDERSTATUS" => "O",
                 "O_SHIPPRIORITY" => 0,
                 "O_TOTALPRICE" => 173_665
               }
               | _rest
             ] = result1.rows

      assert {:ok, %Avalanche.Result{} = result2} =
               Avalanche.run(
                 "SELECT * FROM SNOWFLAKE_SAMPLE_DATA.WEATHER.DAILY_14_TOTAL LIMIT 1",
                 [],
                 c.options
               )

      assert result2.num_rows == 1

      assert [%{"T" => %NaiveDateTime{}, "V" => _stuff1}] = result2.rows
    end

    test "auto loads partitions", c do
      assert {:ok, %Avalanche.Result{} = result} =
               Avalanche.run(
                 "SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS ORDER BY O_ORDERKEY LIMIT ?",
                 [1000],
                 c.options
               )

      assert result.num_rows == 1000
    end
  end
end
