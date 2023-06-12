defmodule AvalancheIntegrationTest do
  @moduledoc """
  These are tests that can be set up to be run locally. These hit the Snowflake
  api and are excluded by default.

  We support two kinds of authentication strategies: private key and token based.

  Once the auth step is cleared (using the strategy of your choice) we can then
  run tests that exercise the features we want. This is why we have more tests
  using `token_integration` than `priv_key_integration`. We prove both work,
  but focused on one (not favoring either, use what works for you and your team
  the best).

  `AVALANCHE_ROLE` notes:
  You may have different ROLES set up in Snowflake and the OAuth token you
  generate may not have access to do what the tests below attempt to do. A
  private key that is shared with a team may have access to different roles
  than your personal one does.
  """

  use ExUnit.Case, async: false

  import Avalanche.TestFixtures
  import Mox

  setup :set_mox_from_context
  setup :verify_on_exit!

  @moduletag :integration

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
    Application.put_env(:avalanche, :jwt_impl, Avalanche.JWTs.JWTJokenImpl)
    Application.put_env(:avalanche, :telemetry_dispatch_impl, Avalanche.Telemetry.TelemetryDispatchImpl)

    on_exit(fn ->
      Application.put_env(:avalanche, :jwt_impl, JWTBehaviourMock)
      Application.put_env(:avalanche, :telemetry_dispatch_impl, TelemetryDispatchBehaviourMock)
    end)

    :ok
  end

  describe "run/4 with OAuth token" do
    setup do
      options = test_options()
      [options: options]
    end

    test "returns a Result struct", c do
      assert {:ok, %Avalanche.Result{} = result} = Avalanche.run("select 1;", [], [], c.options)
      assert result.num_rows == 1
    end
  end

  describe "run/4 with Key Pair token" do
    setup do
      options = test_key_pair_options()
      [options: options]
    end

    test "returns a Result struct", c do
      assert {:ok, %Avalanche.Result{} = result} = Avalanche.run("select 1;", [], [], c.options)
      assert result.num_rows == 1
    end
  end

  describe "run/4" do
    setup do
      options = test_options()
      [options: options]
    end

    test "allows bind variables", c do
      Application.put_env(:avalanche, :telemetry_dispatch_impl, TelemetryDispatchBehaviourMock)

      expect(TelemetryDispatchBehaviourMock, :execute, fn [:avalanche, :query, :start],
                                                          %{system_time: _},
                                                          %{params: %{"1" => %{type: "FIXED", value: "33"}}, query: _} ->
        :ok
      end)

      expect(TelemetryDispatchBehaviourMock, :execute, fn [:avalanche, :query, :stop],
                                                          %{duration: _},
                                                          %{params: %{"1" => %{type: "FIXED", value: "33"}}, query: _} ->
        :ok
      end)

      assert {:ok, %Avalanche.Result{} = result} = Avalanche.run("select ?;", [33], [], c.options)
      assert result.num_rows == 1

      Application.put_env(:avalanche, :telemetry_dispatch_impl, Avalanche.Telemetry.TelemetryDispatchImpl)
    end

    test "parses result body into list of maps", c do
      assert {:ok, %Avalanche.Result{} = result1} =
               Avalanche.run(
                 "SELECT *, 9 as number FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS ORDER BY O_ORDERKEY LIMIT ?",
                 [2],
                 [],
                 c.options
               )

      assert result1.num_rows == 2

      assert [
               %{
                 "NUMBER" => 9,
                 "O_CLERK" => "Clerk#000000951",
                 "O_COMMENT" => "nstructions sleep furiously among ",
                 "O_CUSTKEY" => 36_901,
                 "O_ORDERDATE" => ~D[1996-01-02],
                 "O_ORDERKEY" => 1,
                 "O_ORDERPRIORITY" => "5-LOW",
                 "O_ORDERSTATUS" => "O",
                 "O_SHIPPRIORITY" => 0,
                 "O_TOTALPRICE" => _
               }
               | _rest
             ] = result1.rows

      # statement_handles should be nil when not a multi-statement query
      assert {:ok, nil} = Map.fetch(result1, :statement_handles)
    end

    test "auto loads partitions", c do
      assert {:ok, %Avalanche.Result{} = result} =
               Avalanche.run(
                 "SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS ORDER BY O_ORDERKEY LIMIT ?",
                 [20_000],
                 [],
                 c.options
               )

      assert result.num_rows == 20_000
    end

    test "async query and status to get results", c do
      assert {:ok, %Avalanche.Result{status: :running, statement_handle: statement_handle, num_rows: nil, rows: nil}} =
               Avalanche.run(
                 "SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS ORDER BY O_ORDERKEY LIMIT ?",
                 [3],
                 [async: true],
                 c.options
               )

      assert {:ok, %Avalanche.Result{num_rows: 3}} = Avalanche.status(statement_handle, [], c.options)
    end

    # test "generate flamegraph", c do
    #   query = "SELECT * FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS ORDER BY O_ORDERKEY LIMIT ?"

    #   :eflambe.apply({Avalanche, :run, [query, [20000], c.options]}, open: :speedscope)
    # end
  end

  describe "run/4 multi-statement" do
    setup do
      options = test_options()
      [options: options]
    end

    test "handles multi-statement requests", c do
      assert {:ok, %Avalanche.Result{statement_handles: statement_handles} = result} =
               Avalanche.run("begin transaction;select ?;select ? as two;commit;", [1, 2], [], c.options)

      assert result.status == :complete
      assert length(statement_handles) == 4

      [sh1, sh2, sh3, sh4] = statement_handles

      assert {:ok, %Avalanche.Result{rows: [%{"status" => "Statement executed successfully."}]}} =
               Avalanche.status(sh1, [], c.options)

      assert {:ok, %Avalanche.Result{rows: [%{"?" => 1.0}]}} = Avalanche.status(sh2, [], c.options)
      assert {:ok, %Avalanche.Result{rows: [%{"TWO" => 2.0}]}} = Avalanche.status(sh3, [], c.options)

      assert {:ok, %Avalanche.Result{rows: [%{"status" => "Statement executed successfully."}]}} =
               Avalanche.status(sh4, [], c.options)
    end
  end

  describe "decode_data/1 (integration)" do
    @describetag integration: true

    setup do
      options = test_options()
      [options: options]
    end

    test "decode real data from Snowflake", c do
      assert {:ok, %Avalanche.Result{} = result1} =
               Avalanche.run(
                 "SELECT *, 9 as number FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS ORDER BY O_ORDERKEY LIMIT ?",
                 [2],
                 [],
                 c.options
               )

      assert result1.num_rows == 2

      assert [
               %{
                 "NUMBER" => 9,
                 "O_CLERK" => "Clerk#000000951",
                 "O_COMMENT" => "nstructions sleep furiously among ",
                 "O_CUSTKEY" => 36_901,
                 "O_ORDERDATE" => ~D[1996-01-02],
                 "O_ORDERKEY" => 1,
                 "O_ORDERPRIORITY" => "5-LOW",
                 "O_ORDERSTATUS" => "O",
                 "O_SHIPPRIORITY" => 0,
                 "O_TOTALPRICE" => _
               }
               | _rest
             ] = result1.rows
    end
  end

  describe "TokenCache" do
    setup do
      key = :crypto.hash(:md5, @priv_key)
      Cachex.del(:token_cache, key)
      :ok
    end

    @tag :jwt
    test "Private Key Token - works as expected" do
      {"KEYPAIR_JWT", jwt} =
        Avalanche.TokenCache.fetch_token(account: "test-account", user: "test-user", priv_key: @priv_key)

      assert {:ok, %{"alg" => "RS256", "typ" => "JWT"}} = Avalanche.JWTs.peek_header(jwt)

      assert {:ok,
              %{
                "exp" => _,
                "iat" => _,
                "iss" => iss,
                "sub" => "TEST-ACCOUNT.TEST-USER"
              }} = Avalanche.JWTs.peek_claims(jwt)

      assert "TEST-ACCOUNT.TEST-USER.SHA256:" <> _fingerprint = iss
    end
  end
end
