defmodule Pan.Job.PushMissingSearchIndex do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(state) do
    # give app three quiet minutes in the beginning
    Process.send_after(self(), :work, 3 * 60 * 1000)
    {:ok, state}
  end

  @impl true
  def handle_info(:work, state) do
    Pan.Search.push_missing()
    # search for missing Images roughly every 3 minutes
    Process.send_after(self(), :work, 3 * 60 * 1000)
    {:noreply, state}
  end
end
