defmodule Avalanche.BindingsTest do
  use ExUnit.Case

  doctest Avalanche.Bindings

  describe "encode_params/1" do
    test "raises with a helpful message when we cannot bind the variables in a statement" do
      msg = """
      application_error: Unable to encode value: nil

      The value above will likely generate incorrect and unexpected results even
      if the SQL it generated was valid.

      If you believe there is an issue, please report it here:
      https://github.com/HGInsights/avalanche/issues
      """

      assert_raise Avalanche.Error, msg, fn ->
        Avalanche.Bindings.encode_params([123, nil])
      end
    end
  end
end
