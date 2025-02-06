defmodule Avalanche.Steps.DecodeData do
  @moduledoc """
  A custom `Req` pipeline step to decode the `body.data` returned by Snowflake.
  """

  require Logger

  @unix_epoch ~D[1970-01-01]

  @doc """
  Decodes response `body.data` based on the `resultSetMetaData`.

  https://docs.snowflake.com/en/developer-guide/sql-api/reference.html#label-sql-api-reference-resultset-resultsetmetadata

  ## Options

    * `:downcase_column_names` - Downcase the result's column names.
  """
  def attach(%Req.Request{} = request, options \\ []) do
    request
    |> Req.Request.register_options([:downcase_column_names])
    |> Req.Request.merge_options(options)
    |> Req.Request.append_response_steps(decode_data: &decode_data/1)
  end

  def decode_data(request_response)

  def decode_data({request, %{body: ""} = response}) do
    {request, response}
  end

  def decode_data({request, %{status: 200, body: body} = response}) do
    downcase_column_names = Map.fetch!(request.options, :downcase_column_names)

    row_types =
      case Map.get(body, "resultSetMetaData") do
        nil -> Req.Request.get_private(request, :avalanche_row_types, [])
        metadata -> Map.fetch!(metadata, "rowType")
      end

    data = Map.fetch!(body, "data")

    decoded_data = decode_data_rows(row_types, data, downcase_column_names)

    {request, %Req.Response{response | body: Map.put(body, "data", decoded_data)}}
  end

  def decode_data(request_response), do: request_response

  defp decode_data_rows(types, data, downcase_column_names) when is_list(data) do
    Enum.map(data, fn row ->
      Enum.zip_reduce(types, row, %{}, fn type, value, result ->
        column_name = maybe_downcased_column_name(type, downcase_column_names)
        column_value = decode(type, value)
        Map.put(result, column_name, column_value)
      end)
    end)
  end

  defp decode_data_rows(types, %Stream{} = data, downcase_column_names) do
    Stream.map(data, fn row ->
      Enum.zip_reduce(types, row, %{}, fn type, value, result ->
        column_name = maybe_downcased_column_name(type, downcase_column_names)
        column_value = decode(type, value)
        Map.put(result, column_name, column_value)
      end)
    end)
  end

  defp decode_data_rows(types, data, downcase_column_names) do
    decode_data_rows(types, Stream.map(data, & &1), downcase_column_names)
  end

  defp maybe_downcased_column_name(type, true), do: type |> Map.fetch!("name") |> String.downcase()
  defp maybe_downcased_column_name(type, false), do: Map.fetch!(type, "name")

  defp decode(_type, value) when is_nil(value), do: nil

  defp decode(%{"type" => "fixed" = type, "scale" => scale}, value) when scale > 0 do
    case Float.parse(value) do
      {_float, _rest} -> Decimal.new(value)
      :error -> return_raw(type, value, :fixed_float_parse_error)
    end
  end

  defp decode(%{"type" => "fixed" = type}, value) do
    case Integer.parse(value) do
      {integer, _rest} -> integer
      :error -> return_raw(type, value, :integer_parse_error)
    end
  end

  defp decode(%{"type" => "float" = type}, value) do
    case Float.parse(value) do
      {float, _rest} -> float
      :error -> return_raw(type, value, :float_parse_error)
    end
  end

  defp decode(%{"type" => "real" = type}, value) do
    case Float.parse(value) do
      {float, _rest} -> float
      :error -> return_raw(type, value, :real_parse_error)
    end
  end

  defp decode(%{"type" => "text"}, value), do: value

  defp decode(%{"type" => "boolean"}, value), do: value == "true"

  # Integer value (in a string) of the number of days since the epoch (e.g. 18262).
  defp decode(%{"type" => "date" = type}, value) do
    case Integer.parse(value) do
      {days, _rest} -> Date.add(@unix_epoch, days)
      :error -> return_raw(type, value, :date_parse_error)
    end
  end

  defp decode(%{"type" => "time" = type}, value) do
    case Time.from_iso8601(value) do
      {:ok, time} -> time
      {:error, error} -> return_raw(type, value, error)
    end
  end

  defp decode(%{"type" => "timestamp_ltz" = type}, value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _utc_offset} -> datetime
      {:error, error} -> return_raw(type, value, error)
    end
  end

  defp decode(%{"type" => "timestamp_ntz" = type}, value) do
    case NaiveDateTime.from_iso8601(value) do
      {:ok, datetime} -> datetime
      {:error, error} -> return_raw(type, value, error)
    end
  end

  defp decode(%{"type" => "timestamp_tz" = type}, value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _utc_offset} -> datetime
      {:error, error} -> return_raw(type, value, error)
    end
  end

  defp decode(%{"type" => "object" = type}, value) do
    case Jason.decode(value) do
      {:ok, json} -> json
      {:error, error} -> return_raw(type, value, error)
    end
  end

  # maybe json, maybe something else
  defp decode(%{"type" => "variant" = type}, value) do
    case Jason.decode(value) do
      {:ok, json} -> json
      {:error, error} -> return_raw(type, value, error)
    end
  end

  defp decode(%{"type" => "array" = type}, value) do
    case Jason.decode(value) do
      {:ok, json} -> json
      {:error, error} -> return_raw(type, value, error)
    end
  end

  defp decode(%{"type" => type}, value) do
    Logger.warning("Failed decode of unsupported type: #{type}")
    value
  end

  defp return_raw(type, value, error) do
    error_msg =
      case error do
        %{__exception__: true} = exception -> Exception.message(exception)
        _ -> error
      end

    Logger.warning("Failed decode of '#{type}' type: #{error_msg}")
    value
  end
end
