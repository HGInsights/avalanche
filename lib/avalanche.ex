defmodule Avalanche do
  @external_resource "README.md"

  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  @default_snowflake_timeout 172_800

  @options_schema NimbleOptions.new!(
                    server: [
                      type: :string,
                      required: true,
                      doc: "Snowflake server to sned requests to."
                    ],
                    warehouse: [
                      type: :string,
                      required: true,
                      doc: "Snowflake warehouse for the statement execution."
                    ],
                    database: [
                      type: :string,
                      required: true,
                      doc: "Snowflake database to sned requests to."
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
                           keyword_list: [
                             account: [type: :string],
                             user: [type: :string],
                             priv_key: [type: :string]
                           ]
                         ]},
                      required: true,
                      doc: "Snowflake authentication via OAuth token or Key Pair."
                    ],
                    finch: [
                      type: :any,
                      doc:
                        "Finch pool to use. See `Finch` module documentation for more information on starting pools."
                    ],
                    finch_options: [
                      type: :keyword_list,
                      default: [],
                      doc:
                        "Options passed down to Finch when making the request. See `Finch.request/3` for more information."
                    ]
                  )

  @doc """
  Submits SQL statements to Snowflake for execution.

    * `:statement` - the SQL statement that you want to execute

    * `:params` - list of values for the bind variables in the statement

  ## Options

  #{NimbleOptions.docs(@options_schema)}

  The `options` are merged with default options set with `default_options/1`.
  """
  @spec run(String.t(), list(), keyword()) :: any() | {:error, Avalanche.Error.t()}
  def run(statement, params \\ [], options \\ []) do
    with opts <- Keyword.merge(default_options(), options),
         {:ok, valid_opts} <- validate_options(opts) do
      statement
      |> Avalanche.StatementRequest.build(params, valid_opts)
      |> Avalanche.StatementRequest.run()
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
    with {:ok, opts} <- validate_options(options) do
      Application.put_env(:avalanche, :default_options, opts)
    end
  end

  defp validate_options(options) do
    case NimbleOptions.validate(options, @options_schema) do
      {:ok, opts} -> {:ok, opts}
      {:error, error} -> {:error, Avalanche.Error.new(:invalid_options, Exception.message(error))}
    end
  end
end
