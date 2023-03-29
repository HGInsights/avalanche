defmodule Avalanche.TokenCacheTest do
  use ExUnit.Case
  use Mimic

  import ExUnit.CaptureLog

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

  setup :set_mimic_global

  setup do
    key = :crypto.hash(:md5, @priv_key)
    Cachex.del(:token_cache, key)
    :ok
  end

  describe "fetch_token/1" do
    test "OAuth Token" do
      assert {"OAUTH", "test"} = TokenCache.fetch_token("test")
    end

    test "Private Key Token" do
      {"KEYPAIR_JWT", jwt} = TokenCache.fetch_token(account: "test-account", user: "test-user", priv_key: @priv_key)

      assert {:ok, %{"alg" => "RS256", "typ" => "JWT"}} = Joken.peek_header(jwt)

      assert {:ok,
              %{
                "exp" => _,
                "iat" => _,
                "iss" => iss,
                "sub" => "TEST-ACCOUNT.TEST-USER"
              }} = Joken.peek_claims(jwt)

      assert "TEST-ACCOUNT.TEST-USER.SHA256:" <> _fingerprint = iss
    end

    test "failure to sign jwt token logs and returns :error" do
      Mimic.expect(Joken.Signer, :sign, fn _, _ -> {:error, :jwt_sign_failed} end)

      {result, log} =
        with_log(fn ->
          TokenCache.fetch_token(account: "test-account", user: "test-user", priv_key: @priv_key)
        end)

      assert log =~ "TokenCache.fetch_token/1 failed: :jwt_sign_failed"
      assert result == :error
    end
  end
end
