defmodule Pan.Job do
  use GenServer
  alias PanWeb.Podcast

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(state) do
    Podcast.get_one_stale()
    |> Podcast.import_stale()
    schedule_work()
    {:ok, state}
  end

  @impl true
  def handle_info(:work, state) do

    schedule_work()
    {:noreply, state}
  end

  defp schedule_work do
    # run after 10 minutes
    Process.send_after(self(), :work, 10 * 60 * 1000)
  end
end
