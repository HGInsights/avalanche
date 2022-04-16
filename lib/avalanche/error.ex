defmodule Avalanche.Error do
  @moduledoc """
  Common application error.
  """

  @type meta :: map() | keyword()

  @typedoc "The exception type"
  @type t :: %__MODULE__{
          :reason => atom(),
          :message => String.t(),
          :meta => meta(),
          :original_error => any(),
          stacktrace: nil | Exception.stacktrace()
        }

  defexception reason: :application_error,
               message: "",
               meta: [],
               original_error: nil,
               stacktrace: nil

  @doc """
  Creates a new Error from a message string or another error

  Examples:

      # A string will be used as message
      iex> alias Avalanche.Error
      iex> Error.new("These are the error message")
      %Error{message: "These are the error message"}
      # Error structs are returned unchanged
      iex> Error.new(%Error{reason: :some_reason})
      %Error{reason: :some_reason}
      # Anything else will be used as the `original_error`
      iex> Error.new(%RuntimeError{message: "oops!"})
      %Error{original_error: %RuntimeError{message: "oops!"}}
  """
  @spec new(any) :: t
  def new(%__MODULE__{} = error) do
    error
  end

  def new(message) when is_binary(message) do
    %__MODULE__{message: message}
  end

  def new(reason) when is_atom(reason) do
    %__MODULE__{reason: reason}
  end

  def new(error) do
    %__MODULE__{original_error: error}
  end

  @doc """
  Builds an Error struct.

  Examples:

      iex> alias Avalanche.Error
      iex> Error.new(:bad, "Bad Things", %{data: "things"})
      %Error{__exception__: true, message: "Bad Things", meta: %{data: "things"}, reason: :bad}
  """
  @spec new(atom(), String.t(), meta()) :: t()
  def new(reason, message, meta \\ %{}) when is_binary(message) do
    %__MODULE__{reason: reason, message: message, meta: Map.new(meta)}
  end

  @doc """
  Builds an Error struct with a reason of `:application_error`.

  Examples:
      iex> alias Avalanche.Error
      iex> Error.application_error("Bad Things", %{data: "things"})
      %Error{__exception__: true, message: "Bad Things", meta: %{data: "things"}, reason: :application_error}
  """
  @spec application_error(binary(), meta()) :: t()
  def application_error(message, meta \\ %{}) do
    new(:application_error, message, meta)
  end

  @doc """
  Formats a Error for printing/logging.

  This returns a verbose, multi-line string.
  """
  @spec format(t()) :: binary
  def format(%__MODULE__{} = error) do
    """
    #{error.reason}: #{error.message}
    meta: #{inspect(error.meta)}
    original_error: #{format_error(error.original_error)}
    #{error.stacktrace && Exception.format_stacktrace(error.stacktrace)}
    """
  end

  @doc """
  Returns the Error message.

  Examples:

      iex> alias Avalanche.Error
      iex> error = Error.application_error("Bad Things", %{data: "things"})
      iex> Error.message(error)
      "application_error: Bad Things"
  """
  @impl Exception
  @spec message(t()) :: binary
  def message(%__MODULE__{} = error) do
    "#{error.reason}: #{error.message}"
  end

  @spec format_error(term) :: binary
  defp format_error(error) do
    cond do
      Exception.exception?(error) ->
        "** (" <> inspect(error.__struct__) <> ") " <> Exception.message(error)

      is_binary(error) ->
        error

      true ->
        inspect(error)
    end
  end
end
