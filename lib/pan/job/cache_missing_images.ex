defmodule Pan.Job.CacheMissingImages do
  use GenServer

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
end
