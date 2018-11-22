defmodule Toxic.Watcher do
  @moduledoc false

  use GenServer

  def start_link(default) do
    GenServer.start_link(__MODULE__, default)
  end

  def push(pid, item) do
    GenServer.cast(pid, {:push, item})
  end

  def pop(pid) do
    GenServer.call(pid, :pop)
  end

  @impl true
  def init(stack) do
    {:ok, stack}
  end

  @impl true
  def handle_call(:pop, _from, [head | tail]) do
    {:reply, head, tail}
  end

  @impl true
  def handle_cast({:push, item}, state) do
    {:noreply, [item | state]}
  end

  @impl true
  def handle_info(:check, state) do
    # Do the desired work here
    # Reschedule once more
    schedule_check()
    {:noreply, state}
  end

  defp schedule_check() do
    # In 2 hours
    Process.send_after(self(), :check, 2 * 60 * 60 * 1000)
  end

  def get_auth(topic) do
  end

  def get_endpoint(topic) do
  end

  def handshake() do
  end

  def subscribe() do
  end

  def connect() do
  end
end
