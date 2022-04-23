defmodule Avalanche.Result do
  @moduledoc """
  The Result struct returned from any successful query.


  Fields:

  * `:statement_handle` - the unique identifier for the statement being executed

  * `:num_rows` - the number of fetched or affected rows

  * `:rows` - the result set. A list of maps with, each inner map corresponding to a
  row and each element in the map corresponds to a column.

  """

  defstruct [:statement_handle, :num_rows, :rows]

  @type t() :: %__MODULE__{
          statement_handle: String.t(),
          num_rows: non_neg_integer() | nil,
          rows: list(map()) | nil
        }
end
