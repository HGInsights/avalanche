defmodule Avalanche.Steps.GetPartitionsTest do
  use ExUnit.Case, async: true

  import Avalanche.TestFixtures
  import Mox

  setup :verify_on_exit!

  setup do
    bypass = Bypass.open()
    server = "http://localhost:#{bypass.port}"
    options = test_options(server: server)

    options =
      Keyword.merge(options,
        poll: [delay: 50, max_attempts: 2],
        get_partitions: [max_concurrency: 2, timeout: :timer.seconds(60)]
      )

    [bypass: bypass, url: "http://localhost:#{bypass.port}", options: options]
  end

  describe "run/4" do
    test "does nothing when body is empty", c do
      expect(TelemetryDispatchBehaviourMock, :execute, fn [:avalanche, :query, :start],
                                                          %{system_time: _},
                                                          %{params: _, query: _} ->
        :ok
      end)

      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, "")
      end)

      assert {:ok, %Avalanche.Result{} = result} = Avalanche.run("select 1;", [], [], c.options)

      assert result.num_rows == 0
      assert result.rows == []
    end

    @tag :capture_log
    test "returns a Result struct with data form all partitions", c do
      expect(TelemetryDispatchBehaviourMock, :execute, fn [:avalanche, :query, :start],
                                                          %{system_time: _},
                                                          %{params: _, query: _} ->
        :ok
      end)

      statement_handle = "e4ce975e-f7ff-4b5e-b15e-bf25f59371ae"

      result_set =
        result_set_fixture(%{
          "resultSetMetaData" => %{
            "numRows" => 10,
            "partitionInfo" => [
              %{"rowCount" => 3},
              %{"rowCount" => 3},
              %{"rowCount" => 4}
            ],
            "data" => [["0", "zero"], ["1", "one"], ["2", "two"]]
          },
          "statementHandle" => statement_handle
        })

      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(result_set))
      end)

      Bypass.expect(
        c.bypass,
        "GET",
        "/api/v2/statements/#{statement_handle}",
        fn conn ->
          body =
            case Map.fetch!(conn.query_params, "partition") do
              "1" -> %{"data" => [["3", "three"], ["4", "four"], ["5", "five"]]}
              "2" -> %{"data" => [["6", "six"], ["7", "seven"], ["8", "eight"], ["9", "nine"]]}
            end

          conn
          |> Plug.Conn.put_resp_header("content-type", "application/json")
          |> Plug.Conn.send_resp(200, Jason.encode!(body))
        end
      )

      assert {:ok, %Avalanche.Result{} = result} = Avalanche.run("select 1;", [], [], c.options)

      assert result.num_rows == 10

      assert [
               %{"COLUMN1" => 0, "COLUMN2" => "zero"},
               %{"COLUMN1" => 1, "COLUMN2" => "one"},
               %{"COLUMN1" => 2, "COLUMN2" => "two"},
               %{"COLUMN1" => 3, "COLUMN2" => "three"},
               %{"COLUMN1" => 4, "COLUMN2" => "four"},
               %{"COLUMN1" => 5, "COLUMN2" => "five"},
               %{"COLUMN1" => 6, "COLUMN2" => "six"},
               %{"COLUMN1" => 7, "COLUMN2" => "seven"},
               %{"COLUMN1" => 8, "COLUMN2" => "eight"},
               %{"COLUMN1" => 9, "COLUMN2" => "nine"}
             ] = result.rows
    end

    @tag :capture_log
    test "returns an Error when data form all partitions can't be fetched", c do
      expect(TelemetryDispatchBehaviourMock, :execute, fn [:avalanche, :query, :start],
                                                          %{system_time: _},
                                                          %{params: _, query: _} ->
        :ok
      end)

      statement_handle = "e4ce975e-f7ff-4b5e-b15e-bf25f59371ae"

      result_set =
        result_set_fixture(%{
          "resultSetMetaData" => %{
            "numRows" => 10,
            "partitionInfo" => [
              %{"rowCount" => 3},
              %{"rowCount" => 3},
              %{"rowCount" => 4}
            ],
            "data" => [["0", "zero"], ["1", "one"], ["2", "two"]]
          },
          "statementHandle" => statement_handle
        })

      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(result_set))
      end)

      Bypass.expect(
        c.bypass,
        "GET",
        "/api/v2/statements/#{statement_handle}",
        fn conn ->
          {status, body} =
            case Map.fetch!(conn.query_params, "partition") do
              "1" ->
                {200, %{"data" => [["3", "three"], ["4", "four"], ["5", "five"]]}}

              "2" ->
                {202, %{"statementStatusUrl" => "/api/v2/statements/#{statement_handle}"}}
            end

          conn
          |> Plug.Conn.put_resp_header("content-type", "application/json")
          |> Plug.Conn.send_resp(status, Jason.encode!(body))
        end
      )

      assert {:error,
              %Avalanche.Error{
                meta: %{error: %{message: "Fetching all partitions failed."}},
                reason: :request_timeout
              }} = Avalanche.run("select 1;", [], [], c.options)
    end

    test "returns a Result struct with initial data when partitions is empty", c do
      expect(TelemetryDispatchBehaviourMock, :execute, fn [:avalanche, :query, :start],
                                                          %{system_time: _},
                                                          %{params: _, query: _} ->
        :ok
      end)

      statement_handle = "e4ce975e-f7ff-4b5e-b15e-bf25f59371ae"

      result_set =
        result_set_fixture(%{
          "resultSetMetaData" => %{
            "numRows" => 3,
            "partitionInfo" => [],
            "data" => [["0", "zero"], ["1", "one"], ["2", "two"]]
          },
          "statementHandle" => statement_handle
        })

      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(result_set))
      end)

      assert {:ok, %Avalanche.Result{} = result} = Avalanche.run("select 1;", [], [], c.options)

      assert result.num_rows == 3

      assert [
               %{"COLUMN1" => 0, "COLUMN2" => "zero"},
               %{"COLUMN1" => 1, "COLUMN2" => "one"},
               %{"COLUMN1" => 2, "COLUMN2" => "two"}
             ] = result.rows
    end
  end

  describe "status/3" do
    @tag :capture_log
    test "returns a Result struct with data form all partitions", c do
      statement_handle = "e4ce975e-f7ff-4b5e-b15e-bf25f59371ae"

      result_set =
        result_set_fixture(%{
          "resultSetMetaData" => %{
            "numRows" => 10,
            "partitionInfo" => [
              %{"rowCount" => 3},
              %{"rowCount" => 3},
              %{"rowCount" => 4}
            ],
            "data" => [["0", "zero"], ["1", "one"], ["2", "two"]]
          },
          "statementHandle" => statement_handle
        })

      Bypass.expect(c.bypass, "GET", "/api/v2/statements/#{statement_handle}", fn conn ->
        body =
          case Map.fetch!(conn.query_params, "partition") do
            "1" -> %{"data" => [["3", "three"], ["4", "four"], ["5", "five"]]}
            "2" -> %{"data" => [["6", "six"], ["7", "seven"], ["8", "eight"], ["9", "nine"]]}
            _ -> result_set
          end

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(body))
      end)

      assert {:ok, %Avalanche.Result{} = result} = Avalanche.status(statement_handle, [], c.options)

      assert result.num_rows == 10

      assert [
               %{"COLUMN1" => 0, "COLUMN2" => "zero"},
               %{"COLUMN1" => 1, "COLUMN2" => "one"},
               %{"COLUMN1" => 2, "COLUMN2" => "two"},
               %{"COLUMN1" => 3, "COLUMN2" => "three"},
               %{"COLUMN1" => 4, "COLUMN2" => "four"},
               %{"COLUMN1" => 5, "COLUMN2" => "five"},
               %{"COLUMN1" => 6, "COLUMN2" => "six"},
               %{"COLUMN1" => 7, "COLUMN2" => "seven"},
               %{"COLUMN1" => 8, "COLUMN2" => "eight"},
               %{"COLUMN1" => 9, "COLUMN2" => "nine"}
             ] = result.rows
    end
  end
end
