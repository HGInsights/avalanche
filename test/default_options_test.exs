defmodule DefaultOptionsTest do
  use ExUnit.Case, async: false

  setup do
    on_exit(fn -> Application.put_env(:avalanche, :default_options, []) end)
  end

  test "default options can be set and retrieved" do
    assert Avalanche.default_options() == []

    Avalanche.default_options(
      server: "test.com",
      token: "test",
      warehouse: "test",
      database: "test",
      schema: "test",
      role: "test",
      timeout: 0
    )

    assert Avalanche.default_options() == [
             {:receive_timeout, 50_000},
             {:decode_data, [downcase_column_names: false]},
             {:get_partitions, [timeout: 120_000]},
             {:poll, [delay: 2500, max_attempts: 30]},
             {:server, "test.com"},
             {:token, "test"},
             {:warehouse, "test"},
             {:database, "test"},
             {:schema, "test"},
             {:role, "test"},
             {:timeout, 0}
           ]
  end

  test "options are validated and return error with details" do
    assert {:error,
            %Avalanche.Error{
              message: message,
              meta: %{},
              original_error: nil,
              reason: :invalid_options,
              stacktrace: nil
            }} = Avalanche.default_options(bad: "test")

    assert message =~ "unknown options [:bad], valid options are:"
  end

  test "options allow token with string value for OAuth" do
    assert :ok =
             Avalanche.default_options(
               server: "test",
               token: "test",
               warehouse: "test",
               database: "test",
               schema: "test",
               role: "test"
             )
  end

  test "options allow token with account, user, priv_key for Key Pair Auth" do
    assert {:error,
            %Avalanche.Error{
              message:
                "expected :token to match at least one given type, but didn't match any. Here are the reasons why it didn't match each of the allowed types:\n\n  * unknown options [:userx], valid options are: [:account, :user, :priv_key] (in options [:token])\n  * expected :token to be a string, got: [account: \"test\", userx: \"test\", priv_key: \"test\"]",
              reason: :invalid_options
            }} =
             Avalanche.default_options(
               server: "test",
               token: [account: "test", userx: "test", priv_key: "test"],
               warehouse: "test",
               database: "test",
               schema: "test",
               role: "test"
             )

    assert :ok =
             Avalanche.default_options(
               server: "test",
               token: [account: "test", user: "test", priv_key: "test"],
               warehouse: "test",
               database: "test",
               schema: "test",
               role: "test"
             )
  end

  test "Req.request/1 options are allowed" do
    assert :ok =
             Avalanche.default_options(
               server: "test",
               token: "test",
               warehouse: "test",
               database: "test",
               schema: "test",
               role: "test",
               retry: false,
               follow_redirects: false
             )

    assert Avalanche.default_options() == [
             receive_timeout: 50_000,
             decode_data: [downcase_column_names: false],
             get_partitions: [timeout: 120_000],
             poll: [delay: 2500, max_attempts: 30],
             timeout: 3600,
             server: "test",
             token: "test",
             warehouse: "test",
             database: "test",
             schema: "test",
             role: "test",
             retry: false,
             follow_redirects: false
           ]
  end
end
