defmodule Avalanche.JWTs.JWTJokenImpl do
  @moduledoc """
  Delegates to Joken (https://github.com/joken-elixir/joken)

  We ignore test coverage here because this is tested by the :integration test we have setup.

  We don't run :integration tests in CI, so we are ignoring the report here.
  """

  @behaviour Avalanche.JWTs.JWTBehaviour

  # coveralls-ignore-start
  @impl true
  def generate_claims(claim_options, sub) do
    claim_options
    |> Joken.Config.default_claims()
    |> Joken.Config.add_claim("sub", fn -> sub end)
    |> Joken.generate_claims()
  end

  @impl true
  def create_signer(alg, key) do
    Joken.Signer.create(alg, key)
  end

  @impl true
  def sign(claims, signer) do
    Joken.Signer.sign(claims, signer)
  end

  @impl true
  def peek_claims(jwt) do
    Joken.peek_claims(jwt)
  end

  @impl true
  def peek_header(jwt) do
    Joken.peek_header(jwt)
  end

  # coveralls-ignore-stop
end
