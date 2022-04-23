defmodule DefaultOptionsTest do
  use ExUnit.Case, async: true

  alias Avalanche.TestHelper

  describe "run/3" do
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
        |> Plug.Conn.send_resp(200, Jason.encode!(result_set))
      end)

      assert {:ok, _result} = Avalanche.run("select 1;", [], c.options)
    end

    test "returns a Result struct for successful responses", c do
      result_set = result_set_fixture()

      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(result_set))
      end)

      assert {:ok, %Avalanche.Result{} = result} = Avalanche.run("select 1;", [], c.options)

      assert result.num_rows == 3

      assert [
               %{"COLUMN1" => 0, "COLUMN2" => "zero"},
               %{"COLUMN1" => 1, "COLUMN2" => "one"},
               %{"COLUMN1" => 2, "COLUMN2" => "two"}
             ] = result.rows
    end

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

      assert {:ok, %Avalanche.Result{} = result} = Avalanche.run("select 1;", [], c.options)

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

  describe "run/3 errors" do
    setup do
      bypass = Bypass.open()
      server = "http://localhost:#{bypass.port}"
      options = TestHelper.test_options(server: server)

      [bypass: bypass, url: "http://localhost:#{bypass.port}", options: options]
    end

    test "returns an unauthorized Error for 400 response code", c do
      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        Plug.Conn.send_resp(conn, 400, "no")
      end)

      assert {
               :error,
               %Avalanche.Error{
                 message: "Bad Request",
                 meta: %{
                   error: "no",
                   headers: _headers
                 },
                 reason: :bad_request
               }
             } = Avalanche.run("select 1;", [], c.options)
    end

    test "returns an unauthorized Error for 401 response code", c do
      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        Plug.Conn.send_resp(conn, 401, "no")
      end)

      assert {:error, %Avalanche.Error{reason: :unauthorized}} =
               Avalanche.run("select 1;", [], c.options)
    end

    test "returns an unauthorized Error for 403 response code", c do
      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        Plug.Conn.send_resp(conn, 403, "no")
      end)

      assert {:error, %Avalanche.Error{reason: :forbidden}} =
               Avalanche.run("select 1;", [], c.options)
    end

    test "returns an unauthorized Error for 404 response code", c do
      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        Plug.Conn.send_resp(conn, 404, "no")
      end)

      assert {:error, %Avalanche.Error{reason: :not_found}} =
               Avalanche.run("select 1;", [], c.options)
    end

    test "returns an unauthorized Error for 405 response code", c do
      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        Plug.Conn.send_resp(conn, 405, "no")
      end)

      assert {:error, %Avalanche.Error{reason: :method_not_allowed}} =
               Avalanche.run("select 1;", [], c.options)
    end

    test "returns an unauthorized Error for 415 response code", c do
      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        Plug.Conn.send_resp(conn, 415, "no")
      end)

      assert {:error, %Avalanche.Error{reason: :unsupported_media_type}} =
               Avalanche.run("select 1;", [], c.options)
    end

    test "returns an unauthorized Error for 429 response code", c do
      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        Plug.Conn.send_resp(conn, 429, "no")
      end)

      assert {:error, %Avalanche.Error{reason: :too_many_requests}} =
               Avalanche.run("select 1;", [], c.options)
    end

    test "returns an unauthorized Error for 500 response code", c do
      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        Plug.Conn.send_resp(conn, 500, "no")
      end)

      assert {:error, %Avalanche.Error{reason: :internal_server_error}} =
               Avalanche.run("select 1;", [], c.options)
    end

    test "returns an unauthorized Error for 503 response code", c do
      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        Plug.Conn.send_resp(conn, 503, "no")
      end)

      assert {:error, %Avalanche.Error{reason: :service_unavailable}} =
               Avalanche.run("select 1;", [], c.options)
    end

    test "returns an unauthorized Error for 504 response code", c do
      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        Plug.Conn.send_resp(conn, 504, "no")
      end)

      assert {:error, %Avalanche.Error{reason: :gateway_timeout}} =
               Avalanche.run("select 1;", [], c.options)
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

    TestHelper.deep_merge(defaults, attrs)
  end
end
