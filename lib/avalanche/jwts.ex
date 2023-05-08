defmodule Avalanche.JWTs do
  @moduledoc """
  Context for JWTs
  """

  def generate_claims(claim_options, sub) do
    impl().generate_claims(claim_options, sub)
  end

  def create_signer(alg, key) do
    impl().create_signer(alg, key)
  end

  def sign(claims, signer) do
    impl().sign(claims, signer)
  end

  def peek_claims(jwt) do
    impl().peek_claims(jwt)
  end

  def peek_header(jwt) do
    impl().peek_header(jwt)
  end

  defp impl do
    Application.get_env(:avalanche, :jwt_impl, Avalanche.JWTs.JWTJokenImpl)
  end
end
