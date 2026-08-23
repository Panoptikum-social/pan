defmodule Pan.Job.ImportStalePodcasts do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(state) do
    # give app a quiet minute in the beginning
    Process.send_after(self(), :work, 60 * 1000)
    {:ok, state}
  end

  @impl true
  def handle_info(:work, state) do
    # search for stale Podcast immediately, if one had been found, otherwise wait 10 seconds
    wait_for_seconds =
      PanWeb.Podcast.get_one_stale()
      |> PanWeb.Podcast.import_stale()

    Process.send_after(self(), :work, wait_for_seconds * 1000)
    {:noreply, state}
  end
end
