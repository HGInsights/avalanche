defmodule Avalanche.TokenCacheTest do
  use ExUnit.Case

  import ExUnit.CaptureLog
  import Mox

  alias Avalanche.TokenCache

  @priv_key """
  -----BEGIN PRIVATE KEY-----
  MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCVvLzS+7pUm0Lw
  CAS3Tl7xPvT9FF/wEh2T0WlAUliki6+LhLqHFfXiNDYaZl1ytjRXhJH5/Ix3lFE6
  qGuRaqGRWe+rOLit7nRSerP8WgQIylTS+6x0NiBExqHfl87TUu3MaHDMrxu6smuD
  NUUPq9H/0+cYoVGLLbEygDQUHVcVXpzV1myi7+JmUOhbVphwBOYhwch/itcsvcDE
  JxBXNG+qYdDNvcp+MwedkB9JaUfY8TRdxNycnDZKcJ080rVUNnMXm8Bhgx8IW83T
  X09sKX663bykUnkYwc1WfwySC2G8qO9wpIcEV+uLyR2ewPM4LPtDEd9INCLEJ6z0
  gQuHXomPAgMBAAECggEBAJSOV9gKnuZp05NIoUUrn85A49ZibHxFvMp2rLGAASne
  3B7TZCu5geUWX8b5YCT62BssD5exE7tfjudfSLlQzVLjo4CAGdmWBhn+Wqs2s2H1
  OwrHXmU9fe4+E0M93ZiTYhG2XJL199DWSww1wXq2wPXLSi+JfNlUT8UGpKSAJ3Gu
  k+y8zP+tFtmqmcp+jeaHp3vxtOnrjrpTgnY4XfoqbB0UF+1U1XvUDfK4v6F2EIud
  ys0VSC8yg+whf0Vb+RC643qQT2ZoTn278RfcUJJMSlajS9+4YXlX9PfNyPEZq1jr
  l4aoahtoG+IpmjExAYwgd8tG/PffYMvslIgVrjdQIsECgYEAxlxhT75xtpFnZiI+
  q4C2IT5LOCxcLWOUKsxiIcDFFwIFNN5g7yJigrRBNoqQyaPybv0+kj/Xpq1fLyNd
  Owdco1JyRdAsHCGlVeW2i0r8rx554ELxGDps+SqHm5cicrEiLBoItbBvZgyiq2Iv
  tizvb1A2KqdbtiQwZIG7WMFSeTkCgYEAwT9bRxUN9yPzXqRHoLCKs60r8Q6H0NX9
  M7gBlKKXczZiqySXYoOTH2HjQWdWagKa3ZZy5gIC7jUWbMPpzlmPebpHwaHcm0fP
  wA8/DqC5CZ5iPpxcANcMuIR3EXuJlmpK1houE10xBFSHDJjoKYK8Y7H6Jb36zT9r
  Tdj9hPzEAQcCgYA+OdaxHG4xtpV4Pb/pLzxzW0ZffdMAzh85+dnC+uUZHaIifqxr
  +B5tIDzg7kETcGHqHXmWiX6OJA8bC34AuYN/HKsKaY6c2JU0SBamxcRU7zuOdZGK
  ZzGuTIAz+Apvbk/pA9W9oXagzc/t8aREAv6trb0ATnX/woSH0wbBhgvoSQKBgEc9
  dAjgWiWhuzZImZ9Ddd6HGIvlL2xtdsp6KxsAVZTDl9w/wQ8wMix/iaey0MiD7VOD
  AxiH5UyrhXjTQH4xxhK5+XoIkass7gl/lV9vIMfK+6zZN5GXtbjQHJT1VeN9i9ki
  DZpV4JwYDTE3rV6gM5MNKYqAXtULbCNmuw8rn5ZBAoGBAJxlIJmwMwuNzrJPmY+D
  abS8HVIbD5XReu8FeFC/uo4lKVGScmcUzHLZ71lp9MoXpYTyFEbTGlQev1k5gzz8
  pN9gogg1mfJNHxuf2+cg0hYGR2b1DSzYZ8BiKcHmiK0tYkEB8s256siZa2y54uU9
  GEjRBZ0LIpuFh9slabjxfRUk
  -----END PRIVATE KEY-----
  """

  setup do
    key = :crypto.hash(:md5, @priv_key)
    Cachex.del(:token_cache, key)
    :ok
  end

  setup :set_mox_from_context
  setup :verify_on_exit!

  describe "fetch_token/1" do
    test "OAuth Token" do
      assert {"OAUTH", "test"} = TokenCache.fetch_token("test")
    end

    # Priv key - success -> see :integration tests

    test "Priv key - failure to sign jwt token logs and returns :error" do
      expect(JWTBehaviourMock, :generate_claims, fn _claim_options, _sub ->
        claims = %{
          "exp" => 1_683_402_121,
          "iat" => 1_683_398_581,
          "iss" => "TEST-ACCOUNT.TEST-USER.SHA256:Cs+Qax+bWkinZLzQc13sOWqV5u6rvhzNbzUJpktMg2s=",
          "sub" => "TEST-ACCOUNT.TEST-USER"
        }

        {:ok, claims}
      end)

      expect(JWTBehaviourMock, :create_signer, fn "RS256", %{"pem" => @priv_key} ->
        %{
          jwk: %{},
          jws: %{
            alg: {:jose_jws_alg_rsa_pkcs1_v1_5, :RS256},
            b64: :undefined,
            fields: %{"typ" => "JWT"}
          },
          alg: "RS256"
        }
      end)

      expect(JWTBehaviourMock, :sign, fn _claims, _signer ->
        {:error, :jwt_sign_failed}
      end)

      {result, log} =
        with_log(fn ->
          TokenCache.fetch_token(account: "test-account", user: "test-user", priv_key: @priv_key)
        end)

      assert log =~ "TokenCache.fetch_token/1 failed: :jwt_sign_failed"
      assert result == :error
    end
  end

  describe "token_from_options/1" do
    test "oauth works as expected" do
      assert {:ok, {"OAUTH", "some binary"}} = TokenCache.token_from_options("some binary")
    end

    test "priv_key works as expected - uses JWTs" do
      expect(JWTBehaviourMock, :generate_claims, fn _claim_options, _sub ->
        claims = %{
          "exp" => 1_683_402_121,
          "iat" => 1_683_398_581,
          "iss" => "TEST-ACCOUNT.TEST-USER.SHA256:Cs+Qax+bWkinZLzQc13sOWqV5u6rvhzNbzUJpktMg2s=",
          "sub" => "TEST-ACCOUNT.TEST-USER"
        }

        {:ok, claims}
      end)

      expect(JWTBehaviourMock, :create_signer, fn "RS256", %{"pem" => @priv_key} ->
        %{
          jwk: %{},
          jws: %{
            alg: {:jose_jws_alg_rsa_pkcs1_v1_5, :RS256},
            b64: :undefined,
            fields: %{"typ" => "JWT"}
          },
          alg: "RS256"
        }
      end)

      expect(JWTBehaviourMock, :sign, fn _claims, _signer ->
        {:ok, "signed_token"}
      end)

      token_options = [
        account: "test-account",
        user: "test-user",
        priv_key: @priv_key
      ]

      assert {:ok, {"KEYPAIR_JWT", _valid_token}} = TokenCache.token_from_options(token_options)
    end
  end
end
