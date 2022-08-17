defmodule AvalancheTest do
  use ExUnit.Case, async: true

  import Avalanche.TestFixtures

  setup do
    bypass = Bypass.open()
    server = "http://localhost:#{bypass.port}"
    options = test_options(server: server)

    [bypass: bypass, url: "http://localhost:#{bypass.port}", options: options]
  end

  describe "run/3" do
    @tag :capture_log
    test "sends POST request to /api/v2/statements", c do
      result_set = result_set_fixture()

      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(result_set))
      end)

      assert {:ok, _result} = Avalanche.run("select 1;", [], [], c.options)
    end

    @tag :capture_log
    test "returns a Result struct for successful responses", c do
      result_set = result_set_fixture()

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

    @tag :capture_log
    test "async param defaults to false", c do
      result_set = result_set_fixture()

      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        assert Map.get(conn.params, "async") == "false"

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(result_set))
      end)

      assert {:ok, _result} = Avalanche.run("select 1;", [], [], c.options)
    end

    @tag :capture_log
    test "async param can be set to true", c do
      response = %{
        "code" => "333334",
        "message" =>
          "Asynchronous execution in progress. Use provided query id to perform query monitoring and management.",
        "statementHandle" => "01a6547a-0401-b636-0023-350369cb45aa",
        "statementStatusUrl" => "/api/v2/statements/01a6547a-0401-b636-0023-350369cb45aa"
      }

      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        assert Map.get(conn.params, "async") == "true"

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(202, Jason.encode!(response))
      end)

      assert {:ok, %Avalanche.Result{num_rows: nil, rows: nil, statement_handle: _}} =
               Avalanche.run("select 1;", [], [async: true], c.options)
    end
  end

  describe "run/3 errors" do
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
             } = Avalanche.run("select 1;", [], [], c.options)
    end

    test "returns an unauthorized Error for 401 response code", c do
      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        Plug.Conn.send_resp(conn, 401, "no")
      end)

      assert {:error, %Avalanche.Error{reason: :unauthorized}} = Avalanche.run("select 1;", [], [], c.options)
    end

    test "returns an unauthorized Error for 403 response code", c do
      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        Plug.Conn.send_resp(conn, 403, "no")
      end)

      assert {:error, %Avalanche.Error{reason: :forbidden}} = Avalanche.run("select 1;", [], [], c.options)
    end

    test "returns an unauthorized Error for 404 response code", c do
      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        Plug.Conn.send_resp(conn, 404, "no")
      end)

      assert {:error, %Avalanche.Error{reason: :not_found}} = Avalanche.run("select 1;", [], [], c.options)
    end

    test "returns an unauthorized Error for 405 response code", c do
      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        Plug.Conn.send_resp(conn, 405, "no")
      end)

      assert {:error, %Avalanche.Error{reason: :method_not_allowed}} = Avalanche.run("select 1;", [], [], c.options)
    end

    test "returns an unauthorized Error for 408 response code", c do
      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        Plug.Conn.send_resp(conn, 408, "no")
      end)

      assert {:error, %Avalanche.Error{reason: :request_timeout}} = Avalanche.run("select 1;", [], [], c.options)
    end

    test "returns an unauthorized Error for 422 response code", c do
      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(422, ~s<{
          "code" : "002140",
          "sqlState" : "42601",
          "message" : "SQL compilation error",
          "statementHandle" : "e4ce975e-f7ff-4b5e-b15e-bf25f59371ae",
          "statementStatusUrl" : "/api/v2/statements/e4ce975e-f7ff-4b5e-b15e-bf25f59371ae"
        }>)
      end)

      assert {:error,
              %Avalanche.Error{
                reason: :unprocessable_entity,
                meta: %{
                  error: %{
                    "code" => "002140",
                    "message" => "SQL compilation error",
                    "sqlState" => "42601",
                    "statementHandle" => "e4ce975e-f7ff-4b5e-b15e-bf25f59371ae",
                    "statementStatusUrl" => "/api/v2/statements/e4ce975e-f7ff-4b5e-b15e-bf25f59371ae"
                  }
                }
              }} = Avalanche.run("select 1;", [], [], c.options)
    end

    test "returns an unauthorized Error for 415 response code", c do
      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        Plug.Conn.send_resp(conn, 415, "no")
      end)

      assert {:error, %Avalanche.Error{reason: :unsupported_media_type}} = Avalanche.run("select 1;", [], [], c.options)
    end

    test "returns an unauthorized Error for 429 response code", c do
      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        Plug.Conn.send_resp(conn, 429, "no")
      end)

      assert {:error, %Avalanche.Error{reason: :too_many_requests}} = Avalanche.run("select 1;", [], [], c.options)
    end

    test "returns an unauthorized Error for 500 response code", c do
      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        Plug.Conn.send_resp(conn, 500, "no")
      end)

      assert {:error, %Avalanche.Error{reason: :internal_server_error}} = Avalanche.run("select 1;", [], [], c.options)
    end

    test "returns an unauthorized Error for 503 response code", c do
      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        Plug.Conn.send_resp(conn, 503, "no")
      end)

      assert {:error, %Avalanche.Error{reason: :service_unavailable}} = Avalanche.run("select 1;", [], [], c.options)
    end

    test "returns an unauthorized Error for 504 response code", c do
      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        Plug.Conn.send_resp(conn, 504, "no")
      end)

      assert {:error, %Avalanche.Error{reason: :gateway_timeout}} = Avalanche.run("select 1;", [], [], c.options)
    end
  end

  describe "status/2" do
    @tag :capture_log
    test "sends GET request to /api/v2/statements", c do
      statement_handle = "e4ce975e-f7ff-4b5e-b15e-bf25f59371ae"
      result_set = result_set_fixture(%{"statementHandle" => statement_handle})

      Bypass.expect(c.bypass, "GET", "/api/v2/statements/#{statement_handle}", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(result_set))
      end)

      assert {:ok, _result} = Avalanche.status(statement_handle, [], c.options)
    end

    @tag :capture_log
    test "returns a Result struct for successful responses", c do
      statement_handle = "e4ce975e-f7ff-4b5e-b15e-bf25f59371ae"
      result_set = result_set_fixture(%{"statementHandle" => statement_handle})

      Bypass.expect(c.bypass, "GET", "/api/v2/statements/#{statement_handle}", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(result_set))
      end)

      assert {:ok, result} = Avalanche.status(statement_handle, [], c.options)

      assert result.num_rows == 3

      assert [
               %{"COLUMN1" => 0, "COLUMN2" => "zero"},
               %{"COLUMN1" => 1, "COLUMN2" => "one"},
               %{"COLUMN1" => 2, "COLUMN2" => "two"}
             ] = result.rows
    end

    @tag :capture_log
    test "partition param defaults to 0", c do
      statement_handle = "e4ce975e-f7ff-4b5e-b15e-bf25f59371ae"
      result_set = result_set_fixture(%{"statementHandle" => statement_handle})

      Bypass.expect(c.bypass, "GET", "/api/v2/statements/#{statement_handle}", fn conn ->
        assert Map.get(conn.params, "partition") == "0"

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(result_set))
      end)

      assert {:ok, _result} = Avalanche.status(statement_handle, [], c.options)
    end

    @tag :capture_log
    test "can pass partition number", c do
      statement_handle = "e4ce975e-f7ff-4b5e-b15e-bf25f59371ae"
      result_set = result_set_fixture(%{"statementHandle" => statement_handle})

      Bypass.expect(c.bypass, "GET", "/api/v2/statements/#{statement_handle}", fn conn ->
        assert Map.get(conn.params, "partition") == "3"

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(result_set))
      end)

      assert {:ok, _result} = Avalanche.status(statement_handle, [partition: 3], c.options)
    end

    @tag :capture_log
    test "can make async status request and get empty result if execution in progress", c do
      statement_handle = "e4ce975e-f7ff-4b5e-b15e-bf25f59371ae"

      response = %{
        "code" => "333334",
        "message" =>
          "Asynchronous execution in progress. Use provided query id to perform query monitoring and management.",
        "statementHandle" => statement_handle,
        "statementStatusUrl" => "/api/v2/statements/#{statement_handle}"
      }

      Bypass.expect(c.bypass, "GET", "/api/v2/statements/#{statement_handle}", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(202, Jason.encode!(response))
      end)

      assert {:ok,
              %Avalanche.Result{
                num_rows: nil,
                rows: nil,
                statement_handle: "e4ce975e-f7ff-4b5e-b15e-bf25f59371ae"
              }} = Avalanche.status(statement_handle, [async: true], c.options)
    end
  end

  describe "status/2 errors" do
    @tag :capture_log
    test "returns an unauthorized Error for 422 response code", c do
      statement_handle = "e4ce975e-f7ff-4b5e-b15e-bf25f59371ae"

      Bypass.expect(c.bypass, "GET", "/api/v2/statements/#{statement_handle}", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(500, "")
      end)

      assert {:error, %Avalanche.Error{reason: :internal_server_error}} =
               Avalanche.status(statement_handle, [], c.options)
    end
  end
end
