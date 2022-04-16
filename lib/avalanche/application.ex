defmodule Avalanche.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Avalanche.TokenCache
    ]

    opts = [strategy: :one_for_one, name: Avalanche.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
