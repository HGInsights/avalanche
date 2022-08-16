defmodule Avalanche do
  @external_resource "README.md"

  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  @default_snowflake_timeout 172_800

  @request_options_schema NimbleOptions.new!(
                            server: [
                              type: :string,
                              required: true,
                              doc: "Snowflake server to send requests to."
                            ],
                            warehouse: [
                              type: :string,
                              required: true,
                              doc: "Snowflake warehouse for the statement execution."
                            ],
                            database: [
                              type: :string,
                              required: true,
                              doc: "Snowflake database for the statement execution."
                            ],
                            schema: [
                              type: :string,
                              required: true,
                              doc: "Snowflake schema for the statement execution."
                            ],
                            role: [
                              type: :string,
                              required: true,
                              doc: "Snowflake role for the statement execution."
                            ],
                            timeout: [
                              type: :non_neg_integer,
                              required: false,
                              default: 172_800,
                              doc:
                                "Snowflake timeout for the statement execution. 0 to 604800 (i.e. 7 days) — a value of 0 specifies that the maximum timeout value is enforced."
                            ],
                            token: [
                              type:
                                {:or,
                                 [
                                   :string,
                                   non_empty_keyword_list: [
                                     account: [type: :string],
                                     user: [type: :string],
                                     priv_key: [type: :string]
                                   ]
                                 ]},
                              required: true,
                              doc: "Snowflake authentication via OAuth token or Key Pair."
                            ],
                            poll_options: [
                              type: :non_empty_keyword_list,
                              keys: [
                                delay: [type: :pos_integer],
                                max_polls: [type: :pos_integer]
                              ],
                              doc: "Options to customize polling for the completion of a statement execution."
                            ],
                            get_partitions_options: [
                              type: :non_empty_keyword_list,
                              keys: [
                                max_concurrency: [type: :pos_integer],
                                timeout: [type: :pos_integer]
                              ],
                              doc:
                                "Options to customize retrieving all the partitions of data from a statement execution."
                            ],
                            finch: [
                              type: :any,
                              doc:
                                "Finch pool to use. See `Finch` module documentation for more information on starting pools."
                            ],
                            pool_timeout: [
                              type: :pos_integer,
                              default: 5000,
                              doc: "Finch pool checkout timeout in milliseconds"
                            ],
                            receive_timeout: [
                              type: :pos_integer,
                              default: 15_000,
                              doc: "Finch socket receive timeout in milliseconds"
                            ]
                          )

  @run_options_schema NimbleOptions.new!(
                        async: [
                          type: :boolean,
                          required: false,
                          default: false,
                          doc: "Set to true to execute the statement asynchronously and return the statement handle."
                        ]
                      )

  @status_options_schema NimbleOptions.new!(
                           partition: [
                             type: :non_neg_integer,
                             required: false,
                             default: 0,
                             doc:
                               "Number of the partition of results to return. The number can range from 0 to the total number of partitions minus 1."
                           ]
                         )

  @doc """
  Submits SQL statements to Snowflake for execution.

    * `:statement` - the SQL statement that you want to execute

    * `:params` - list of values for the bind variables in the statement

  #### Run Options

  #{NimbleOptions.docs(@run_options_schema)}

  #### Request Options

  #{NimbleOptions.docs(@request_options_schema)}

  The `request_options` are merged with default options set with `default_options/1`.
  """
  @spec run(String.t(), list(), keyword(), keyword()) :: any() | {:error, Avalanche.Error.t()}
  def run(statement, params \\ [], run_options \\ [], request_options \\ []) do
    with request_opts <- Keyword.merge(default_options(), request_options),
         {:ok, valid_request_opts} <- validate_options(request_opts, @request_options_schema),
         {:ok, valid_run_opts} <- validate_options(run_options, @run_options_schema),
         async <- Keyword.fetch!(valid_run_opts, :async) do
      statement
      |> Avalanche.StatementRequest.build(params, valid_request_opts)
      |> Avalanche.StatementRequest.run(async)
    end
  end

  @doc """
  Checks the status of a statement execution.

    * `:statement_handle` - the unique identifier for an executed statement

  #### Status Options

  #{NimbleOptions.docs(@status_options_schema)}

  #### Request Options

  #{NimbleOptions.docs(@request_options_schema)}

  The `request_options` are merged with default options set with `default_options/1`.
  """
  @spec status(String.t(), keyword(), keyword()) :: any() | {:error, Avalanche.Error.t()}
  def status(statement_handle, status_options \\ [], request_options \\ []) do
    with request_opts <- Keyword.merge(default_options(), request_options),
         {:ok, valid_request_opts} <- validate_options(request_opts, @request_options_schema),
         {:ok, valid_status_opts} <- validate_options(status_options, @status_options_schema),
         partition <- Keyword.fetch!(valid_status_opts, :partition) do
      statement_handle
      |> Avalanche.StatusRequest.build(valid_request_opts)
      |> Avalanche.StatusRequest.run(partition)
    end
  end

  @doc """
  Returns default options.

  See `default_options/1` for more information.
  """
  @spec default_options() :: keyword()
  def default_options do
    options = Application.get_env(:avalanche, :default_options, [])
    Keyword.merge([timeout: @default_snowflake_timeout], options)
  end

  @doc """
  Sets default options.

  The default options are used by `run/2` functions.

  Avoid setting default options in libraries as they are global.
  """
  @spec default_options(keyword()) :: :ok | {:error, Avalanche.Error.t()}
  def default_options(options) do
    with {:ok, opts} <- validate_options(options, @request_options_schema) do
      Application.put_env(:avalanche, :default_options, opts)
    end
  end

  defp validate_options(options, schema) do
    case NimbleOptions.validate(options, schema) do
      {:ok, opts} -> {:ok, opts}
      {:error, error} -> {:error, Avalanche.Error.new(:invalid_options, Exception.message(error))}
    end
  end
end
