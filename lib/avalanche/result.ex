defmodule Avalanche.Result do
  @moduledoc """
  The Result struct returned from any successful query.


  Fields:

  * `:status` - the status of the statement being executed (`:running`, `:complete`)

  * `:statement_handle` - the unique identifier for the statement being executed

  * `:num_rows` - the number of fetched or affected rows

  * `:rows` - the result set. A list of maps with, each inner map corresponding to a
  row and each element in the map corresponds to a column.

  """

  @enforce_keys [:status, :statement_handle]
  defstruct status: :running, statement_handle: nil, num_rows: nil, rows: nil

  @type result_status :: atom()

  @type t() :: %__MODULE__{
          status: result_status(),
          statement_handle: String.t() | nil,
          num_rows: non_neg_integer() | nil,
          rows: list(map()) | nil
        }
end
