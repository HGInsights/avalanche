defmodule Avalanche.TokenCache do
  @moduledoc """
  Token handling and caching.

  Will create and cache a token (`KEYPAIR_JWT`) from a private key and details or cache a given token (`OAUTH`).

  See: https://docs.snowflake.com/en/developer-guide/sql-api/authenticating.html
  """

  require Logger

  @cache :token_cache
  @ttl :timer.minutes(30)
  @janitor_interval :timer.seconds(5)

  # JWT expiration time (59 min)
  @default_exp 60 * 59

  # GenServer
  @spec child_spec(any) :: Supervisor.child_spec()
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  @spec start_link(any()) :: Supervisor.on_start()
  def start_link(_) do
    import Cachex.Spec

    Cachex.start_link(
      name: @cache,
      expiration: expiration(default: @ttl, interval: @janitor_interval)
    )
  end

  @doc """
  Fetches token from the cache or creates and caches token from given options.

  Returns `{"KEYPAIR_JWT", token}` or `{"OAUTH", token}`.
  """
  @spec fetch_token(options :: Keyword.t() | binary()) :: {binary(), binary()} | :error
  @dialyzer {:nowarn_function, fetch_token: 1}
  def fetch_token(options) do
    key = key_from_options(options)

    Cachex.fetch(@cache, key, fn _key ->
      case token_from_options(options) do
        {:ok, token} ->
          {:commit, token}

        {:error, error} ->
          {:ignore, {:error, error}}
      end
    end)
    |> case do
      {:ok, token} ->
        token

      {:commit, token} ->
        token

      {:ignore, {:error, error}} ->
        Logger.error("TokenCache.fetch_token/1 failed: #{inspect(error)}")
        :error
    end
  end

  def token_from_options(token) when is_binary(token), do: {:ok, {"OAUTH", token}}

  def token_from_options(token) do
    account = Keyword.fetch!(token, :account)
    user = Keyword.fetch!(token, :user)
    priv_key = Keyword.fetch!(token, :priv_key)

    sub = "#{String.upcase(account)}.#{String.upcase(user)}"
    iss = "#{sub}.#{public_key_fingerprint(priv_key)}"

    {:ok, claims} = Avalanche.JWTs.generate_claims([iss: iss, default_exp: @default_exp, skip: [:aud, :jti, :nbf]], sub)

    signer = Avalanche.JWTs.create_signer("RS256", %{"pem" => priv_key})

    with {:ok, token} <- Avalanche.JWTs.sign(claims, signer) do
      {:ok, {"KEYPAIR_JWT", token}}
    end
  end

  defp key_from_options(token) when is_binary(token), do: :crypto.hash(:md5, token)

  defp key_from_options(token) do
    priv_key = Keyword.fetch!(token, :priv_key)
    :crypto.hash(:md5, priv_key)
  end

  # SHA256:public_key_fingerprint
  defp public_key_fingerprint(priv_key) do
    encoded =
      priv_key
      |> pubkey_from_privkey()
      |> hash_encode()

    "SHA256:#{encoded}"
  end

  # returns spki encoded public key data
  defp pubkey_from_privkey(priv_key) do
    [pem_entry] = :public_key.pem_decode(priv_key)

    {:RSAPrivateKey, :"two-prime", modulus, pub_exponent, _, _, _, _, _, _, :asn1_NOVALUE} =
      :public_key.pem_entry_decode(pem_entry)

    pub_key = {:RSAPublicKey, modulus, pub_exponent}

    {:SubjectPublicKeyInfo, spki_data, _} = :public_key.pem_entry_encode(:SubjectPublicKeyInfo, pub_key)

    spki_data
  end

  defp hash_encode(data) do
    hash = :crypto.hash(:sha256, data)
    Base.encode64(hash)
  end
end
