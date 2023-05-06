defmodule Avalanche.JWTsTest do
  @moduledoc """
  Since our JWT implementation consists of pure functions, we can use it directly in unit tests
  """
  use ExUnit.Case

  setup do
    Application.put_env(:avalanche, :jwt_impl, Avalanche.JWTs.JWTJokenImpl)

    on_exit(fn ->
      Application.put_env(:avalanche, :jwt_impl, JWTBehaviourMock)
    end)

    jwt =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"

    {:ok, %{jwt: jwt}}
  end

  test "peek_claims/1", %{jwt: jwt} do
    assert {:ok, %{"iat" => _, "name" => "John Doe", "sub" => _}} = Avalanche.JWTs.peek_claims(jwt)
  end

  test "peek_header/1", %{jwt: jwt} do
    assert {:ok, %{"alg" => "HS256", "typ" => "JWT"}} = Avalanche.JWTs.peek_header(jwt)
  end
end
