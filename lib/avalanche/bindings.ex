defmodule Avalanche.Bindings do
  @moduledoc """
  Prepares bindings from list of values.

  https://docs.snowflake.com/en/developer-guide/sql-api/submitting-requests.html#using-bind-variables-in-a-statement
  """

  @doc """
  Encodes the given values into an indexed map of bindings.

  Examples:

      iex> values = [123, 1.23, "uno, dos, tres", false, ~N[2015-01-14 13:00:07], DateTime.from_unix!(1_464_096_368), ~D[2015-01-15]]
      iex> Avalanche.Bindings.encode_params(values)
      %{
        "1" => %{type: "FIXED", value: "123"},
        "2" => %{type: "REAL", value: "1.23"},
        "3" => %{type: "TEXT", value: "uno, dos, tres"},
        "4" => %{type: "BOOLEAN", value: false},
        "5" => %{type: "TEXT", value: "2015-01-14T13:00:07"},
        "6" => %{type: "TEXT", value: "2016-05-24T13:26:08Z"},
        "7" => %{type: "TEXT", value: "2015-01-15"}
      }
  """
  def encode_params(values) when is_list(values) do
    values
    |> Enum.with_index(fn value, index -> {index + 1, value} end)
    |> Enum.reduce(%{}, fn {index, value}, acc ->
      Map.put(acc, to_string(index), encode(value))
    end)
  end

  defp encode(value) when is_integer(value) do
    %{type: "FIXED", value: to_string(value)}
  end

  defp encode(value) when is_float(value) do
    %{type: "REAL", value: to_string(value)}
  end

  defp encode(value) when is_binary(value) do
    %{type: "TEXT", value: value}
  end

  defp encode(value) when is_boolean(value) do
    %{type: "BOOLEAN", value: value}
  end

  defp encode(%NaiveDateTime{} = value) do
    %{type: "TEXT", value: NaiveDateTime.to_iso8601(value)}
  end

  defp encode(%DateTime{} = value) do
    %{type: "TEXT", value: DateTime.to_iso8601(value)}
  end

  defp encode(%Date{} = value) do
    %{type: "TEXT", value: Date.to_iso8601(value)}
  end

  defp encode(any) do
    msg = """
    Unable to encode value: #{inspect(any)}

    The value above will likely generate incorrect and unexpected results even
    if the SQL it generated was valid.

    If you believe there is an issue, please report it here:
    https://github.com/HGInsights/avalanche/issues
    """

    raise Avalanche.Error.application_error(msg)
  end
end
