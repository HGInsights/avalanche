defmodule Avalanche do
  @external_resource "README.md"

  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  @default_snowflake_timeout 3600

  @token_options_schema [
    account: [type: :string, doc: "Snowflake Account ID"],
    user: [type: :string, doc: "User"],
    priv_key: [type: :string, doc: "RSA Private Key"]
  ]

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
                              default: @default_snowflake_timeout,
                              doc:
                                "Snowflake timeout in seconds for the statement execution. 0 to 604800 (i.e. 7 days) — a value of 0 specifies that the maximum timeout value is enforced."
                            ],
                            token: [
                              type: {:or, [:string, non_empty_keyword_list: @token_options_schema]},
                              required: true,
                              doc:
                                "Snowflake authentication via OAuth token (string) or Key Pair (Keyword List): \n\n #{NimbleOptions.docs(@token_options_schema, nest_level: 1)}"
                            ],
                            poll: [
                              type: :non_empty_keyword_list,
                              keys: [
                                delay: [
                                  type: :pos_integer,
                                  doc: "Sleep this number of milliseconds between attempts."
                                ],
                                max_attempts: [
                                  type: :pos_integer,
                                  doc: "Maximum number of poll attempts."
                                ]
                              ],
                              default: [delay: 2500, max_attempts: 30],
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
                                  doc: "Maximum amount of time to wait (in milliseconds)."
                                ]
                              ],
                              default: [timeout: 120_000],
                              doc:
                                "Options to customize retrieving all the partitions of data from a statement's execution."
                            ],
                            decode_data: [
                              type: :non_empty_keyword_list,
                              keys: [
                                downcase_column_names: [
                                  type: :boolean,
                                  doc: "Downcase the result's column names."
                                ]
                              ],
                              default: [downcase_column_names: false],
                              doc: "Options to customize how data is decoded from a statement's execution."
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
                        streaming: [
                          type: :boolean,
                          default: false,
                          doc: "Set to true to stream the result of the statement."
                        ],
                        async: [
                          type: :boolean,
                          default: false,
                          doc: "Set to true to execute the statement asynchronously and return the statement handle."
                        ],
                        request_id: [
                          type: :string,
                          doc: "Unique ID (a UUID) of the API request."
                        ],
                        retry: [
                          type: :boolean,
                          doc: "Set to true only when retrying the statement with a previous `request_id`."
                        ]
                      )

  @status_options_schema NimbleOptions.new!(
                           async: [
                             type: :boolean,
                             default: false,
                             doc: "Set to true to disable polling and waiting for a statement to finish executing."
                           ],
                           partition: [
                             type: :non_neg_integer,
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
  @spec run(String.t(), list(), Keyword.t(), Keyword.t()) :: {:ok, Avalanche.Result.t()} | {:error, Avalanche.Error.t()}
  def run(statement, params \\ [], run_options \\ [], request_options \\ []) do
    start_time = System.monotonic_time()
    metadata = %{params: params, query: statement}

    try do
      with request_opts <- Keyword.merge(default_options(), request_options),
           {:ok, valid_request_opts} <- validate_options(request_opts, @request_options_schema),
           {:ok, valid_run_opts} <- validate_options(run_options, @run_options_schema) do
        statement
        |> Avalanche.StatementRequest.build(params, valid_request_opts)
        |> Avalanche.StatementRequest.run(valid_run_opts)
      end
    catch
      kind, error ->
        Avalanche.Telemetry.exception(:query, start_time, kind, error, __STACKTRACE__, metadata)
        :erlang.raise(kind, error, __STACKTRACE__)
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
  @spec status(String.t(), Keyword.t(), Keyword.t()) :: {:ok, Avalanche.Result.t()} | {:error, Avalanche.Error.t()}
  def status(statement_handle, status_options \\ [], request_options \\ []) do
    start_time = System.monotonic_time()

    try do
      with request_opts <- Keyword.merge(default_options(), request_options),
           {:ok, valid_request_opts} <- validate_options(request_opts, @request_options_schema),
           {:ok, valid_status_opts} <- validate_options(status_options, @status_options_schema),
           async <- Keyword.fetch!(valid_status_opts, :async),
           partition <- Keyword.fetch!(valid_status_opts, :partition) do
        statement_handle
        |> Avalanche.StatusRequest.build(valid_request_opts)
        |> Avalanche.StatusRequest.run(async, partition)
      end
    catch
      kind, error ->
        metadata =
          %{statement_handle: statement_handle}
          |> Map.put(:async, Keyword.get(status_options, :async))
          |> Map.put(:partition, Keyword.get(status_options, :partition))

        Avalanche.Telemetry.exception(:query, start_time, kind, error, __STACKTRACE__, metadata)
        :erlang.raise(kind, error, __STACKTRACE__)
    end
  end

  @doc """
  Returns default options.

  See `default_options/1` for more information.
  """
  @spec default_options() :: Keyword.t()
  def default_options do
    Application.get_env(:avalanche, :default_options, [])
  end

  @doc """
  Sets default options.

  The default options are used by `run/2` functions.

  Avoid setting default options in libraries as they are global.
  """
  @spec default_options(Keyword.t()) :: :ok | {:error, Avalanche.Error.t()}
  def default_options(options) do
    with {:ok, opts} <- validate_options(options, @request_options_schema) do
      Application.put_env(:avalanche, :default_options, opts)
    end
  end

  @doc """
  List of available Req request options.

  See `Req.request/1` for more information.
  """
  @spec available_req_options :: list(atom())
  def available_req_options do
    ~W(user_agent compressed range http_errors base_url params auth form json compress_body compressed raw decode_body output follow_redirects location_trusted max_redirects retry retry_delay max_retries cache cache_dir plug finch connect_options receive_timeout pool_timeout unix_socket)a
  end

  defp validate_options(options, schema) do
    {req_options, options} = Keyword.split(options, available_req_options())

    case NimbleOptions.validate(options, schema) do
      {:ok, opts} ->
        merged_opts = Keyword.merge(opts, req_options)
        {:ok, merged_opts}

      {:error, error} ->
        {:error, Avalanche.Error.new(:invalid_options, Exception.message(error))}
    end
  end
end
