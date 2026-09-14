defmodule Pan.Job.CacheMissingImages do
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(state) do
    # give app two quiet minutes in the beginning
    Process.send_after(self(), :work, 2 * 60 * 1000)
    {:ok, state}
  end

  @impl true
  def handle_info(:work, state) do
    PanWeb.Image.cache_missing()
    # search for missing Images every five minutes
    Process.send_after(self(), :work, 5 * 60 * 1000)
    {:noreply, state}
  end

  # A stray {:timeout, _ref, :try_ipv4} can land here some time after an
  # HTTP call (this job downloads thumbnails) — see
  # Pan.Job.RefreshPodcastMetadata's handle_info/2 catch-all for the full
  # explanation (hackney's happy-eyeballs race).
  @impl true
  def handle_info(message, state) do
    Logger.warning("CacheMissingImages received unexpected message: #{inspect(message)}")
    {:noreply, state}
  end
end
