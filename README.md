# Avalanche

[![CI](https://github.com/HGInsights/avalanche/actions/workflows/elixir-ci.yml/badge.svg)](https://github.com/HGInsights/avalanche/actions/workflows/elixir-ci.yml)
[![hex.pm version](https://img.shields.io/hexpm/v/avalanche.svg)](https://hex.pm/packages/avalanche)
[![hex.pm license](https://img.shields.io/hexpm/l/avalanche.svg)](https://github.com/HGInsights/avalanche/blob/main/LICENSE)
[![Last Updated](https://img.shields.io/github/last-commit/HGInsights/avalanche.svg)](https://github.com/HGInsights/avalanche/commits/main)

<!-- MDOC !-->

Avalanche is an Elixir [Snowflake](https://docs.snowflake.com/en/developer-guide/sql-api/index.html) Connector built on top of the Snowflake SQL API v2.

## Features

* Submit SQL statements for execution.

* Check the status of the execution of a statement.

* Cancel the execution of a statement.

* Manage your deployment (e.g. provision users and roles, create tables, etc.)

## Installation

```elixir
def deps do
  [
    {:avalanche, "~> 0.1.0"}
  ]
end
```

<!-- MDOC !-->

## Acknowledgments

Avalanche is built on top of [Req](https://github.com/hginsights/req) & [Finch](https://github.com/sneako/finch) - thank you!

## Documentation

Documentation is automatically published to [hexdocs.pm](https://hexdocs.pm/avalanche) on release.
You may build the documentation locally with

```
MIX_ENV=docs mix docs
```

## Running tests

You can run unit tests with:
```bash
mix test
```

To set up and run the `integration` tests, you need to:
- `cp .env.test .env.test.local` and adjust the existing variables accordingly.
- obtain a private key and add it to the the `.env.test.local` file if you wish
  to run tests that use the `priv_key` auth strategy
- obtain a `SNOWFLAKE_OAUTH_ACCESS_TOKEN` if you wish to run tests that use the
  `token` auth strategy

You can run all tests and integration tests with:
```bash
SNOWFLAKE_OAUTH_ACCESS_TOKEN=your_token mix test --include integration
```

## Contributing

Issues and PRs are welcome! See our organization [CONTRIBUTING.md](https://github.com/HGInsights/.github/blob/main/CONTRIBUTING.md) for more information about best-practices and passing CI.
