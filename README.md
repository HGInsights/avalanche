# Avalanche

[![CI](https://github.com/hginsights/avalanche/actions/workflows/ci.yml/badge.svg)](https://github.com/hginsights/avalanche/actions/workflows/ci.yml)

[Docs](https://hexdocs.pm/avalanche)

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

Avalanche is built on top of [Req](https://github.com/hginsights/req) & [Finch](http://github.com/keathley/finch) - thank you!

## License

Copyright (c) 2022 HG Insights

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
