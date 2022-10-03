defmodule Avalanche.Steps.DecodeDataTest do
  use ExUnit.Case, async: true

  import Avalanche.TestFixtures
  import ExUnit.CaptureLog

  alias Avalanche.Steps.DecodeData

  describe "decode_data/1" do
    setup do
      [fake_request: %Req.Request{options: %{downcase_column_names: false}}]
    end

    test "does nothing when body is empty", c do
      in_response = %Req.Response{status: 200, body: ""}

      {_request, response} = DecodeData.decode_data({c.fake_request, in_response})

      assert response.body == ""
    end

    test "decodes nil value to nil", c do
      result_set =
        result_set_fixture(%{
          "resultSetMetaData" => %{
            "numRows" => 1,
            "rowType" => [
              %{"name" => "COLUMN", "type" => "fixed"}
            ]
          },
          "data" => [[nil]]
        })

      in_response = %Req.Response{status: 200, body: result_set}

      {_request, response} = DecodeData.decode_data({c.fake_request, in_response})

      assert [%{"COLUMN" => nil}] = response.body["data"]
    end

    test "decodes fixed type to Integer", c do
      result_set =
        result_set_fixture(%{
          "resultSetMetaData" => %{
            "numRows" => 1,
            "rowType" => [
              %{"name" => "COLUMN", "type" => "fixed"}
            ]
          },
          "data" => [["33"]]
        })

      in_response = %Req.Response{status: 200, body: result_set}

      {_request, response} = DecodeData.decode_data({c.fake_request, in_response})

      assert [%{"COLUMN" => 33}] = response.body["data"]
    end

    test "decodes float type to Float", c do
      result_set =
        result_set_fixture(%{
          "resultSetMetaData" => %{
            "numRows" => 1,
            "rowType" => [
              %{"name" => "COLUMN", "type" => "float"}
            ]
          },
          "data" => [["33.3"]]
        })

      in_response = %Req.Response{status: 200, body: result_set}

      {_request, response} = DecodeData.decode_data({c.fake_request, in_response})

      assert [%{"COLUMN" => 33.3}] = response.body["data"]
    end

    test "decodes real type to Float", c do
      result_set =
        result_set_fixture(%{
          "resultSetMetaData" => %{
            "numRows" => 1,
            "rowType" => [
              %{"name" => "COLUMN", "type" => "real"}
            ]
          },
          "data" => [["33.3"]]
        })

      in_response = %Req.Response{status: 200, body: result_set}

      {_request, response} = DecodeData.decode_data({c.fake_request, in_response})

      assert [%{"COLUMN" => 33.3}] = response.body["data"]
    end

    test "decodes text type to Binary", c do
      result_set =
        result_set_fixture(%{
          "resultSetMetaData" => %{
            "numRows" => 1,
            "rowType" => [
              %{"name" => "COLUMN", "type" => "text"}
            ]
          },
          "data" => [["This is some text."]]
        })

      in_response = %Req.Response{status: 200, body: result_set}

      {_request, response} = DecodeData.decode_data({c.fake_request, in_response})

      assert [%{"COLUMN" => "This is some text."}] = response.body["data"]
    end

    test "decodes boolean type to Boolean", c do
      result_set =
        result_set_fixture(%{
          "resultSetMetaData" => %{
            "numRows" => 1,
            "rowType" => [
              %{"name" => "COLUMN1", "type" => "boolean"},
              %{"name" => "COLUMN2", "type" => "boolean"}
            ]
          },
          "data" => [["true", "false"]]
        })

      in_response = %Req.Response{status: 200, body: result_set}

      {_request, response} = DecodeData.decode_data({c.fake_request, in_response})

      assert [%{"COLUMN1" => true, "COLUMN2" => false}] = response.body["data"]
    end

    test "decodes date type to Date", c do
      result_set =
        result_set_fixture(%{
          "resultSetMetaData" => %{
            "numRows" => 1,
            "rowType" => [
              %{"name" => "COLUMN", "type" => "date"}
            ]
          },
          "data" => [["18262"]]
        })

      in_response = %Req.Response{status: 200, body: result_set}

      {_request, response} = DecodeData.decode_data({c.fake_request, in_response})

      assert [%{"COLUMN" => ~D[2020-01-01]}] = response.body["data"]
    end

    test "decodes time type to Time", c do
      result_set =
        result_set_fixture(%{
          "resultSetMetaData" => %{
            "numRows" => 1,
            "rowType" => [
              %{"name" => "COLUMN", "type" => "time"}
            ]
          },
          "data" => [["20:04:56"]]
        })

      in_response = %Req.Response{status: 200, body: result_set}

      {_request, response} = DecodeData.decode_data({c.fake_request, in_response})

      assert [%{"COLUMN" => ~T[20:04:56]}] = response.body["data"]
    end

    test "decodes timestamp_ltz type to DateTime", c do
      result_set =
        result_set_fixture(%{
          "resultSetMetaData" => %{
            "numRows" => 1,
            "rowType" => [
              %{"name" => "COLUMN", "type" => "timestamp_ltz"}
            ]
          },
          "data" => [["2013-04-28 20:57:01.123456789+07:00"]]
        })

      in_response = %Req.Response{status: 200, body: result_set}

      {_request, response} = DecodeData.decode_data({c.fake_request, in_response})

      assert [%{"COLUMN" => ~U[2013-04-28 13:57:01.123456Z]}] = response.body["data"]
    end

    test "decodes timestamp_ntz type to NaiveDateTime", c do
      result_set =
        result_set_fixture(%{
          "resultSetMetaData" => %{
            "numRows" => 1,
            "rowType" => [
              %{"name" => "COLUMN", "type" => "timestamp_ntz"}
            ]
          },
          "data" => [["2013-04-28 20:57:01.123"]]
        })

      in_response = %Req.Response{status: 200, body: result_set}

      {_request, response} = DecodeData.decode_data({c.fake_request, in_response})

      assert [%{"COLUMN" => ~N[2013-04-28 20:57:01.123]}] = response.body["data"]
    end

    test "decodes timestamp_tz type to DateTime", c do
      result_set =
        result_set_fixture(%{
          "resultSetMetaData" => %{
            "numRows" => 1,
            "rowType" => [
              %{"name" => "COLUMN", "type" => "timestamp_tz"}
            ]
          },
          "data" => [["2013-04-28 20:57:01.123456789+07:00"]]
        })

      in_response = %Req.Response{status: 200, body: result_set}

      {_request, response} = DecodeData.decode_data({c.fake_request, in_response})

      assert [%{"COLUMN" => ~U[2013-04-28 13:57:01.123456Z]}] = response.body["data"]
    end

    test "decodes object type to decoded JSON", c do
      result_set =
        result_set_fixture(%{
          "resultSetMetaData" => %{
            "numRows" => 1,
            "rowType" => [
              %{"name" => "COLUMN", "type" => "object"}
            ]
          },
          "data" => [[~s<{"test" : [1, "two", 3]}>]]
        })

      in_response = %Req.Response{status: 200, body: result_set}

      {_request, response} = DecodeData.decode_data({c.fake_request, in_response})

      assert [%{"COLUMN" => %{"test" => [1, "two", 3]}}] = response.body["data"]
    end

    test "decodes variant type to decoded JSON if data is JSON", c do
      result_set =
        result_set_fixture(%{
          "resultSetMetaData" => %{
            "numRows" => 1,
            "rowType" => [
              %{"name" => "COLUMN", "type" => "variant"}
            ]
          },
          "data" => [[~s<{"test" : [1, "two", 3]}>]]
        })

      in_response = %Req.Response{status: 200, body: result_set}

      {_request, response} = DecodeData.decode_data({c.fake_request, in_response})

      assert [%{"COLUMN" => %{"test" => [1, "two", 3]}}] = response.body["data"]
    end

    @tag :capture_log
    test "decodes variant type to Binary if data is not JSON", c do
      result_set =
        result_set_fixture(%{
          "resultSetMetaData" => %{
            "numRows" => 1,
            "rowType" => [
              %{"name" => "COLUMN", "type" => "variant"}
            ]
          },
          "data" => [[~s(<xml>yeah!</xml>)]]
        })

      in_response = %Req.Response{status: 200, body: result_set}

      {_request, response} = DecodeData.decode_data({c.fake_request, in_response})

      assert [%{"COLUMN" => "<xml>yeah!</xml>"}] = response.body["data"]
    end

    test "decodes array type to List", c do
      result_set =
        result_set_fixture(%{
          "resultSetMetaData" => %{
            "numRows" => 1,
            "rowType" => [
              %{"name" => "COLUMN", "type" => "array"}
            ]
          },
          "data" => [[~s<[1, "two", 3, {"key" : "value"}]>]]
        })

      in_response = %Req.Response{status: 200, body: result_set}

      {_request, response} = DecodeData.decode_data({c.fake_request, in_response})

      assert [%{"COLUMN" => [1, "two", 3, %{"key" => "value"}]}] = response.body["data"]
    end

    # credo:disable-for-this-file Credo.Check.Readability.SinglePipe
    [
      {"fixed", "a3a3", "integer_parse_error"},
      {"float", "a3a3", "float_parse_error"},
      {"real", "a3a3", "real_parse_error"},
      {"date", "a3a3", "date_parse_error"},
      {"time", "a3a3", "invalid_format"},
      {"timestamp_ltz", "a3a3", "invalid_format"},
      {"timestamp_ntz", "a3a3", "invalid_format"},
      {"timestamp_tz", "a3a3", "invalid_format"},
      {"object", "a3a3", "unexpected byte at position 0"},
      {"variant", "a3a3", "unexpected byte at position 0"},
      {"array", "a3a3", "unexpected byte at position 0"}
    ]
    |> Enum.each(fn {type, value, error} ->
      @tag :capture_log
      test "decodes #{type} type to raw value with parse error", c do
        result_set =
          result_set_fixture(%{
            "resultSetMetaData" => %{
              "numRows" => 1,
              "rowType" => [
                %{"name" => "COLUMN", "type" => unquote(type)}
              ]
            },
            "data" => [[unquote(value)]]
          })

        in_response = %Req.Response{status: 200, body: result_set}

        {{_request, response}, log} =
          with_log(fn ->
            DecodeData.decode_data({c.fake_request, in_response})
          end)

        assert log =~ "Failed decode of '#{unquote(type)}' type: #{unquote(error)}"

        assert [%{"COLUMN" => unquote(value)}] = response.body["data"]
      end
    end)

    test "decodes unknown type to raw value with parse error", c do
      result_set =
        result_set_fixture(%{
          "resultSetMetaData" => %{
            "numRows" => 1,
            "rowType" => [
              %{"name" => "COLUMN", "type" => "unknown"}
            ]
          },
          "data" => [["a3a3"]]
        })

      in_response = %Req.Response{status: 200, body: result_set}

      {{_request, response}, log} =
        with_log(fn ->
          DecodeData.decode_data({c.fake_request, in_response})
        end)

      assert log =~ "Failed decode of unsupported type: unknown"

      assert [%{"COLUMN" => "a3a3"}] = response.body["data"]
    end
  end

  describe "run/4" do
    setup do
      bypass = Bypass.open()
      server = "http://localhost:#{bypass.port}"
      options = test_options(server: server)

      options =
        Keyword.merge(options,
          decode_data: [downcase_column_names: true]
        )

      [bypass: bypass, url: "http://localhost:#{bypass.port}", options: options]
    end

    test "returns a Result struct with downcased column names in", c do
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
               %{"column1" => 0, "column2" => "zero"},
               %{"column1" => 1, "column2" => "one"},
               %{"column1" => 2, "column2" => "two"}
             ] = result.rows
    end
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
                 "O_TOTALPRICE" => 173_665
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
