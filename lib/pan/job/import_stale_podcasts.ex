defmodule Pan.Job.ImportStalePodcasts do
  use GenServer
  alias PanWeb.Podcast

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(state) do
    schedule_work()
    {:ok, state}
  end

  @impl true
  def handle_info(:work, state) do
    Podcast.get_one_stale()
    |> Podcast.import_stale()
    schedule_work()
    {:noreply, state}
  end

  defp schedule_work do
    # run each minute
    Process.send_after(self(), :work, 60 * 1000)
  end
end
