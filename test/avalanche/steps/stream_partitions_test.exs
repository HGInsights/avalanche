defmodule Avalanche.Steps.StreamPartitionsTest do
  use ExUnit.Case, async: true
  alias Avalanche.Steps.StreamPartitions

  setup do
    # Set up Task.Supervisor for async streaming
    start_supervised({Task.Supervisor, name: Avalanche.TaskSupervisor})

    # Mock response data
    base_response = %Req.Response{
      status: 200,
      body: %{
        "resultSetMetaData" => %{
          "rowType" => [
            %{"name" => "col1", "type" => "text"}
          ],
          "partitionInfo" => [
            %{"rowCount" => 2},
            %{"rowCount" => 3}
          ]
        },
        "statementStatusUrl" => "https://example.snowflakecomputing.com/status",
        "data" => [["first"]]
      }
    }

    # Mock request with all necessary fields
    request = 
      Req.new(
        url: "https://example.snowflakecomputing.com",
        auth: {:bearer, "test-token"},
        headers: %{"Content-Type" => "application/json"},
        receive_timeout: 120_000
      )
      |> Req.Request.register_options([:max_concurrency, :timeout])  # Register our custom options
      |> Req.Request.merge_options(
        timeout: 120_000,
        max_concurrency: System.schedulers_online()
      )

    {:ok, request: request, base_response: base_response}
  end

  describe "attach/2" do
    test "attaches streaming step to request pipeline" do
      request = %Req.Request{}
      result = StreamPartitions.attach(request)

      assert Keyword.has_key?(result.response_steps, :stream_partitions)
    end
  end

  describe "stream_partitions/1" do
    test "handles empty response body", %{request: request} do
      empty_response = %Req.Response{body: Stream.into([], []), status: 200}
      assert {^request, ^empty_response} = StreamPartitions.stream_partitions({request, empty_response})
    end

    test "handles response with no partitions", %{request: request} do
      response = %Req.Response{
        status: 200,
        body: %{
          "resultSetMetaData" => %{
            "rowType" => [],
            "partitionInfo" => []
          },
          "data" => ""
        }
      }

      {_req, result} = StreamPartitions.stream_partitions({request, response})
      assert Enum.to_list(result.body["data"]) == [""]
    end

    test "handles response with missing fields", %{request: request} do
      response = %Req.Response{
        status: 200,
        body: %{
          "resultSetMetaData" => %{},
          "data" => []
        }
      }

      {_req, result} = StreamPartitions.stream_partitions({request, response})
      assert Enum.to_list(result.body["data"]) == [[]]
    end

    test "processes partitioned response", %{request: request, base_response: response} do
      {_req, result} = StreamPartitions.stream_partitions({request, response})

      assert is_function(result.body["data"])
      assert length(Enum.to_list(result.body["data"])) >= 1
    end
  end
end
