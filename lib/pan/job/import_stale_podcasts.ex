defmodule Pan.Job.ImportStalePodcasts do
  use GenServer
  require Logger

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
      try do
        PanWeb.Podcast.get_one_stale()
        |> PanWeb.Podcast.import_stale()
      rescue
        error ->
          Logger.error(
            "=== ImportStalePodcasts crashed: " <>
              Exception.format(:error, error, __STACKTRACE__) <> " ==="
          )

          # back off before retrying, so a broken feed can't spin-crash the
          # single job process (was seen restart-looping via the
          # supervisor's restart budget, see backlog)
          10
      catch
        kind, reason ->
          Logger.error("=== ImportStalePodcasts crashed (#{kind}): #{inspect(reason)} ===")

          10
      end

    Process.send_after(self(), :work, wait_for_seconds * 1000)
    {:noreply, state}
  end
end
