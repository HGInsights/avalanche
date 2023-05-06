defmodule Avalanche.JWTs.JWTBehaviour do
  @callback create_signer(binary(), map()) :: map()
  @callback generate_claims(keyword(), binary()) :: {:ok, map()} | {:error, atom() | keyword()}
  @callback peek_claims(binary()) :: {:ok, binary()} | {:error, atom() | keyword()}
  @callback peek_header(binary()) :: {:ok, binary()} | {:error, atom() | keyword()}
  @callback sign(map(), map()) :: {:ok, binary()} | {:error, binary()}
end
