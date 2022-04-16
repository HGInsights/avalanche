defmodule AvalancheIntegrationTest do
  use ExUnit.Case, async: true

  alias Avalanche.TestHelper

  @tag integration: true
  describe "run/2 with OAuth token" do
    setup do
      options = TestHelper.test_options()
      [options: options]
    end

    test "returns a Response struct", c do
      assert {:ok, %Avalanche.Response{} = response} = Avalanche.run("select 1;", c.options)
      assert response.status == 200
    end
  end

  @tag integration: true
  describe "run/2 with Key Pair token" do
    setup do
      options = TestHelper.test_key_pair_options()
      [options: options]
    end

    test "returns a Response struct", c do
      assert {:ok, %Avalanche.Response{} = response} = Avalanche.run("select 1;", c.options)
      assert response.status == 200
    end
  end
end
