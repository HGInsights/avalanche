defmodule Avalanche.Steps.PollTest do
  use ExUnit.Case, async: true

  import Avalanche.TestFixtures
  import Mox

  setup :verify_on_exit!

  setup do
    bypass = Bypass.open()
    server = "http://localhost:#{bypass.port}"
    options = test_options(server: server)

    options = Keyword.merge(options, poll: [delay: 50, max_attempts: 2])

    [bypass: bypass, url: "http://localhost:#{bypass.port}", options: options]
  end

  describe "async and timeouts" do
    @tag :capture_log
    test "handles 202 result code for async or longer than 45 second queries", c do
      expect(TelemetryDispatchBehaviourMock, :execute, 2, fn
        [:avalanche, :query, :start], %{system_time: _}, %{params: _, query: _} -> :ok
        [:avalanche, :query, :stop], %{duration: _}, %{params: _, query: _} -> :ok
      end)

      statement_handle = "e4ce975e-f7ff-4b5e-b15e-bf25f59371ae"

      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        query_status_result = ~s<{
          "code" : "333334",
          "message" :
              "Asynchronous execution in progress. Use provided query id to perform query monitoring and management.",
          "statementHandle" : "#{statement_handle}",
          "statementStatusUrl" : "/api/v2/statements/#{statement_handle}"
        }>

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(202, query_status_result)
      end)

      Bypass.expect(c.bypass, "GET", "/api/v2/statements/#{statement_handle}", fn conn ->
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

        body =
          case Map.get(conn.query_params, "partition") do
            "1" -> %{"data" => [["3", "three"], ["4", "four"], ["5", "five"]]}
            "2" -> %{"data" => [["6", "six"], ["7", "seven"], ["8", "eight"], ["9", "nine"]]}
            _ -> result_set
          end

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(body))
      end)

      assert {:ok, %Avalanche.Result{} = result} = Avalanche.run("select 1;", [], [], c.options)

      assert result.num_rows == 10
    end
  end
end
