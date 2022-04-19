defmodule DefaultOptionsTest do
  use ExUnit.Case, async: true

  alias Avalanche.TestHelper

  describe "run/2" do
    setup do
      bypass = Bypass.open()
      server = "http://localhost:#{bypass.port}"
      options = TestHelper.test_options(server: server)

      [bypass: bypass, url: "http://localhost:#{bypass.port}", options: options]
    end

    test "sends POST request to /api/v2/statements", c do
      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        Plug.Conn.send_resp(conn, 200, "ok")
      end)

      assert {:ok, _response} = Avalanche.run("select 1;", [], c.options)
    end

    test "returns a Response struct", c do
      Bypass.expect(c.bypass, "POST", "/api/v2/statements", fn conn ->
        Plug.Conn.send_resp(conn, 200, "ok")
      end)

      assert {:ok, %Avalanche.Response{} = response} = Avalanche.run("select 1;", [], c.options)
      assert response.status == 200
      assert response.body == "ok"
      assert length(response.headers) != 0
    end
  end
end
