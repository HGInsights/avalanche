defmodule Avalanche.Steps.PollTest do
  use ExUnit.Case, async: true

  import Avalanche.TestFixtures

  setup do
    bypass = Bypass.open()
    server = "http://localhost:#{bypass.port}"
    options = test_options(server: server)

    [bypass: bypass, url: "http://localhost:#{bypass.port}", options: options]
  end

  describe "async and timeouts" do
    test "handles 202 result code for async or longer than 45 second queries", c do
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

      assert {:ok, %Avalanche.Result{} = result} = Avalanche.run("select 1;", [], c.options)

      assert result.num_rows == 10
    end
  end
end
