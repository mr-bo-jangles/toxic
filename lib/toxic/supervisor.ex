defmodule Toxic.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      {Toxic.Watcher, name: Toxic.Watcher}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
