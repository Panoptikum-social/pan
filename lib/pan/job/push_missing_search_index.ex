defmodule Pan.Job.PushMissingSearchIndex do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(state) do
    # covers a fresh Manticore instance (e.g. a new QA/Docker volume) where
    # the search tables don't exist yet — a no-op once they do
    send(self(), :ensure_tables)
    {:ok, state}
  end

  @impl true
  def handle_info(:ensure_tables, state) do
    Pan.Search.ensure_tables()
    # give app three quiet minutes in the beginning
    Process.send_after(self(), :work, 3 * 60 * 1000)
    {:noreply, state}
  end

  @impl true
  def handle_info(:work, state) do
    Pan.Search.push_missing()
    # search for missing Images roughly every 3 minutes
    Process.send_after(self(), :work, 3 * 60 * 1000)
    {:noreply, state}
  end
end
