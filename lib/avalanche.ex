defmodule Avalanche do
  @external_resource "README.md"

  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  @default_snowflake_timeout 3600

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
                              default: @default_snowflake_timeout,
                              doc:
                                "Snowflake timeout in seconds for the statement execution. 0 to 604800 (i.e. 7 days) — a value of 0 specifies that the maximum timeout value is enforced."
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
                            poll: [
                              type: :non_empty_keyword_list,
                              keys: [
                                delay: [
                                  type: :pos_integer,
                                  default: 2500,
                                  doc: "Sleep this number of milliseconds between attempts."
                                ],
                                max_attempts: [
                                  type: :pos_integer,
                                  default: 30,
                                  doc: "Maximum number of poll attempts."
                                ]
                              ],
                              doc:
                                "Options to customize polling for the completion of a statement's execution. Synchronous statement execution will wait a maximum of 45 secondes plus the `poll` configuration (75 seconds) for a total of 2 minutes."
                            ],
                            get_partitions: [
                              type: :non_empty_keyword_list,
                              keys: [
                                max_concurrency: [
                                  type: :pos_integer,
                                  doc:
                                    "Sets the maximum number of tasks to run at the same time. The default value is `System.schedulers_online/0`."
                                ],
                                timeout: [
                                  type: :pos_integer,
                                  default: 120_000,
                                  doc: "Maximum amount of time to wait (in milliseconds)."
                                ]
                              ],
                              doc:
                                "Options to customize retrieving all the partitions of data from a statement's execution."
                            ],
                            decode_data: [
                              type: :non_empty_keyword_list,
                              keys: [
                                downcase_column_names: [
                                  type: :boolean,
                                  default: false,
                                  doc: "Downcase the result's column names."
                                ]
                              ],
                              doc: "Options to customize how data is decoded from a statement's execution."
                            ],
                            retry: [type: :any, doc: "See `Req.request/1` for more information."],
                            retry_delay: [type: :any, doc: "See `Req.request/1` for more information."],
                            max_retries: [type: :any, doc: "See `Req.request/1` for more information."],
                            finch: [
                              type: :any,
                              doc:
                                "Finch pool to use. See `Finch` module documentation for more information on starting pools."
                            ],
                            pool_timeout: [
                              type: :pos_integer,
                              default: 5000,
                              doc: "Finch pool checkout timeout in milliseconds."
                            ],
                            receive_timeout: [
                              type: :pos_integer,
                              default: 50_000,
                              doc: """
                              Finch socket receive timeout in milliseconds.
                              The default accounts for Snowflake's 45 second synchronous statement execution timeout.
                              Use the `poll` options if you want to wait longer for a result. Otherwise a statement handle
                              will be returned that you can use with `Avalanche.status/3` to get the result.
                              """
                            ]
                          )

  @run_options_schema NimbleOptions.new!(
                        async: [
                          type: :boolean,
                          required: false,
                          default: false,
                          doc: "Set to true to execute the statement asynchronously and return the statement handle."
                        ],
                        request_id: [
                          type: :string,
                          required: false,
                          doc: "Unique ID (a UUID) of the API request."
                        ],
                        retry: [
                          type: :boolean,
                          required: false,
                          doc: "Set to true only when retrying the statement with a previous `request_id`."
                        ]
                      )

  @status_options_schema NimbleOptions.new!(
                           async: [
                             type: :boolean,
                             required: false,
                             default: false,
                             doc: "Set to true to disable polling and waiting for a statement to finish executing."
                           ],
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
         {:ok, valid_run_opts} <- validate_options(run_options, @run_options_schema) do
      statement
      |> Avalanche.StatementRequest.build(params, valid_request_opts)
      |> Avalanche.StatementRequest.run(valid_run_opts)
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
         async <- Keyword.fetch!(valid_status_opts, :async),
         partition <- Keyword.fetch!(valid_status_opts, :partition) do
      statement_handle
      |> Avalanche.StatusRequest.build(valid_request_opts)
      |> Avalanche.StatusRequest.run(async, partition)
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
