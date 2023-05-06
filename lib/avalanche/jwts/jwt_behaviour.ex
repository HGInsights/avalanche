defmodule Avalanche.JWTs.JWTBehaviour do
  @callback create_signer(binary(), map()) :: map()
  @callback generate_claims(map(), binary()) :: {:ok, map()} | {:error, atom() | Keyword.t()}
  @callback peek_claims(map()) :: {:ok, binary()} | {:error, binary()}
  @callback peek_header(map()) :: {:ok, binary()} | {:error, binary()}
  @callback sign(map(), map()) :: {:ok, binary()} | {:error, binary()}
end
