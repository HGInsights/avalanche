defmodule DefaultOptionsTest do
  use ExUnit.Case, async: true

  alias Avalanche.TestHelper

  describe "run/2" do
    setup do
      bypass = Bypass.open()
      server = "http://localhost:#{bypass.port}"
      options = TestHelper.test_options(server: server)

      [bypass: bypass, url: "http://localhost:#{bypass.port}", options: options]
    end

    test "sends POST request to /api/v2/statements", c do
      result_set = result_set_fixture()

      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, result_set)
      end)

      assert {:ok, _result} = Avalanche.run("select 1;", [], c.options)
    end

    test "returns a Result struct for successful responses", c do
      result_set = result_set_fixture()

      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, result_set)
      end)

      assert {:ok, %Avalanche.Result{} = result} = Avalanche.run("select 1;", [], c.options)

      assert result.num_rows == 3

      assert [
               %{"COLUMN1" => 0, "COLUMN2" => "zero"},
               %{"COLUMN1" => 1, "COLUMN2" => "one"},
               %{"COLUMN1" => 2, "COLUMN2" => "two"}
             ] = result.rows
    end

    test "returns an Error for unsuccessful (not 200) response", c do
      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        Plug.Conn.send_resp(conn, 401, "no")
      end)

      assert {
               :error,
               %Avalanche.Error{
                 message: "Unauthorized",
                 meta: %{
                   body: "no",
                   headers: _headers
                 },
                 reason: :unauthorized
               }
             } = Avalanche.run("select 1;", [], c.options)
    end
  end

  # 202, 408, 422
  # test "handles 202 result code for async or longer than 45 second queries", c do
  #   statement_handle = "e4ce975e-f7ff-4b5e-b15e-bf25f59371ae"

  #   Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
  #     query_status_result = %{
  #       "code" => "0",
  #       "sqlState" => "",
  #       "message" => "successfully executed",
  #       "statementHandle" => statement_handle,
  #       "statementStatusUrl" => "/api/v2/statements/#{statement_handle}"
  #     }

  #     Plug.Conn.send_resp(conn, 202, query_status_result)
  #   end)
  # end

  def result_set_fixture(attrs \\ %{}) do
    result_set =
      Enum.into(attrs, %{
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
        "statementStatusUrl" => "/api/v2/statements/{handle}?requestId={id4}",
        "sqlState" => "00000",
        "statementHandle" => "{handle}",
        "message" => "Statement executed successfully.",
        "createdOn" => 1_620_151_693_299
      })

    Jason.encode!(result_set)
  end
end
