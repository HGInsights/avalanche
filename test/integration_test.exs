defmodule AvalancheIntegrationTest do
  @moduledoc """
  These are tests that can be set up to be run locally. These hit the Snowflake
  api and are excluded by default.

  We support two kinds of authentication strategies: private key and token based.

  Once the auth step is cleared (using the strategy of your choice) we can then
  run tests that exercise the features we want. This is why we have more tests
  using `token_integration` than `priv_key_integration`. We prove both work,
  but focused on one (not favoring either, use what works for you and your team
  the best).

  `AVALANCHE_ROLE` notes:
  You may have different ROLES set up in Snowflake and the OAuth token you
  generate may not have access to do what the tests below attempt to do. A
  private key that is shared with a team may have access to different roles
  than your personal one does.
  """

  use ExUnit.Case, async: false

  import Avalanche.TestFixtures
  import Mox

  setup :verify_on_exit!

  @moduletag :integration

  setup do
    Application.put_env(:avalanche, :telemetry_dispatch_impl, Avalanche.Telemetry.TelemetryDispatchImpl)

    on_exit(fn ->
      Application.put_env(:avalanche, :telemetry_dispatch_impl, TelemetryDispatchBehaviourMock)
    end)

    :ok
  end

  describe "run/2 with OAuth token" do
    setup do
      options = test_options()
      [options: options]
    end

    test "returns a Result struct", c do
      assert {:ok, %Avalanche.Result{} = result} = Avalanche.run("select 1;", [], [], c.options)
      assert result.num_rows == 1
    end
  end

  describe "run/2 with Key Pair token" do
    setup do
      options = test_key_pair_options()
      [options: options]
    end

    test "returns a Result struct", c do
      assert {:ok, %Avalanche.Result{} = result} = Avalanche.run("select 1;", [], [], c.options)
      assert result.num_rows == 1
    end
  end

  describe "run/2" do
    setup do
      options = test_options()
      [options: options]
    end

    test "allows bind variables", c do
      Application.put_env(:avalanche, :telemetry_dispatch_impl, TelemetryDispatchBehaviourMock)

      expect(TelemetryDispatchBehaviourMock, :execute, fn [:avalanche, :query, :start],
                                                          %{system_time: _},
                                                          %{params: %{"1" => %{type: "FIXED", value: "33"}}, query: _} ->
        :ok
      end)

      expect(TelemetryDispatchBehaviourMock, :execute, fn [:avalanche, :query, :stop],
                                                          %{duration: _},
                                                          %{params: %{"1" => %{type: "FIXED", value: "33"}}, query: _} ->
        :ok
      end)

      assert {:ok, %Avalanche.Result{} = result} = Avalanche.run("select ?;", [33], [], c.options)
      assert result.num_rows == 1

      Application.put_env(:avalanche, :telemetry_dispatch_impl, Avalanche.Telemetry.TelemetryDispatchImpl)
    end

    test "parses result body into list of maps", c do
      assert {:ok, %Avalanche.Result{} = result1} =
               Avalanche.run(
                 "SELECT *, 9 as number FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS ORDER BY O_ORDERKEY LIMIT ?",
                 [2],
                 [],
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
                 "O_TOTALPRICE" => _
               }
               | _rest
             ] = result1.rows

      assert {:ok, %Avalanche.Result{} = result2} =
               Avalanche.run(
                 "SELECT * FROM SNOWFLAKE_SAMPLE_DATA.WEATHER.DAILY_14_TOTAL LIMIT 1",
                 [],
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
                 [20_000],
                 [],
                 c.options
               )

      assert result.num_rows == 20_000
    end

    test "async query and status to get results", c do
      assert {:ok, %Avalanche.Result{status: :running, statement_handle: statement_handle, num_rows: nil, rows: nil}} =
               Avalanche.run(
                 "SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS ORDER BY O_ORDERKEY LIMIT ?",
                 [3],
                 [async: true],
                 c.options
               )

      assert {:ok, %Avalanche.Result{num_rows: 3}} = Avalanche.status(statement_handle, [], c.options)
    end

    # test "generate flamegraph", c do
    #   query = "SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS ORDER BY O_ORDERKEY LIMIT ?"

    #   :eflambe.apply({Avalanche, :run, [query, [20000], c.options]}, open: :speedscope)
    # end
  end

  describe "decode_data/1 (integration)" do
    @describetag integration: true

    setup do
      options = test_options()
      [options: options]
    end

    test "decode real data from Snowflake", c do
      assert {:ok, %Avalanche.Result{} = result1} =
               Avalanche.run(
                 "SELECT *, 9 as number FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS ORDER BY O_ORDERKEY LIMIT ?",
                 [2],
                 [],
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
                 "O_TOTALPRICE" => _
               }
               | _rest
             ] = result1.rows

      assert {:ok, %Avalanche.Result{} = result2} =
               Avalanche.run(
                 "SELECT * FROM SNOWFLAKE_SAMPLE_DATA.WEATHER.DAILY_14_TOTAL LIMIT 1",
                 [],
                 [],
                 c.options
               )

      assert result2.num_rows == 1

      assert [%{"T" => %NaiveDateTime{}, "V" => _stuff1}] = result2.rows
    end
  end
end
