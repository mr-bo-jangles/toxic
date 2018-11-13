defmodule Toxic do
  use Application
  @moduledoc """
  Documentation for Toxic.
  """

  require Logger

  import Supervisor.Spec

  def start(_type, _args) do
    children = [
      %{
        id: OutboundQueue,
        start: { Toxic.Storage, :start_link, [[]] }
      },
      %{
        id: InboundQueue,
        start: { Toxic.Storage, :start_link, [[]] }
      },
      %{
        id: Watcher,
        start: { Toxic.Watcher, :start_link, [%{outbound: OutboundQueue, inbound: InboundQueue}]}
      }
    ]
    opts = [strategy: :one_for_one, name: Toxic]
    case Supervisor.start_link(children, opts) do
      {:ok, _} = ok ->
        Logger.info("Starting Toxic")
        ok
      error ->
        Logger.error("Error starting Toxic")
        error
    end
  end
end
