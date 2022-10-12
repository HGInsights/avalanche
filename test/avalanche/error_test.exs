defmodule Avalanche.ErrorTest do
  use ExUnit.Case

  doctest Avalanche.Error

  alias Avalanche.Error

  describe "to_string/1" do
    test "returns the error message when" do
      error = "Failed!" |> RuntimeError.exception() |> Error.new()

      assert "#{error}" == "application_error: Failed!"
    end
  end
end
