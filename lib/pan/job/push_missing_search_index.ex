defmodule Pan.Job.PushMissingSearchIndex do
  use GenServer
  require Logger

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

  # A stray {:timeout, _ref, :try_ipv4} can land here some time after an
  # HTTP call (this job talks to Manticore over HTTP) — see
  # Pan.Job.RefreshPodcastMetadata's handle_info/2 catch-all for the full
  # explanation (hackney's happy-eyeballs race).
  @impl true
  def handle_info(message, state) do
    Logger.warning("PushMissingSearchIndex received unexpected message: #{inspect(message)}")
    {:noreply, state}
  end
end
