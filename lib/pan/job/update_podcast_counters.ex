defmodule Pan.Job.UpdatePodcastCounters do
  use GenServer
  require Logger

  # Nightly recount of every podcast's counters (episodes, likes, followers,
  # subscriptions, latest episode date, publication frequency) via
  # PanWeb.Podcast.update_all_counters/0, the function behind the admin
  # button "update all counters". The stored counts otherwise only change on
  # a like/follow/subscribe toggle or a feed update, so they drift whenever
  # rows disappear another way: user deletion (retention job, admin, self),
  # "delete all my subscriptions", merges (#498). On prod a run takes about
  # 90 s (2026-11-04).
  @run_at ~T[02:22:00]
  @time_zone "Europe/Vienna"

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  @impl true
  def init(state) do
    schedule_next_run()
    {:ok, state}
  end

  @impl true
  def handle_info(:work, state) do
    {microseconds, _results} = :timer.tc(&PanWeb.Podcast.update_all_counters/0)

    Logger.info(
      "UpdatePodcastCounters: all counters updated in #{div(microseconds, 1_000_000)} s"
    )

    schedule_next_run()
    {:noreply, state}
  end

  # See Pan.Job.RefreshPodcastMetadata's handle_info/2 catch-all.
  @impl true
  def handle_info(message, state) do
    Logger.warning("#{__MODULE__} received unexpected message: #{inspect(message)}")
    {:noreply, state}
  end

  defp schedule_next_run do
    Process.send_after(self(), :work, ms_until_next_run(DateTime.utc_now()))
  end

  @doc """
  Milliseconds from `now` until the next 02:22 Vienna time. On the night the
  clocks go forward 02:22 doesn't exist, the run is at 03:00 then; on the
  night they go back it exists twice, the run is at the first one.
  """
  def ms_until_next_run(now) do
    today = now |> DateTime.shift_zone!(@time_zone) |> DateTime.to_date()
    run = next_run_on(today)

    run =
      if DateTime.compare(run, now) == :gt,
        do: run,
        else: next_run_on(Date.add(today, 1))

    DateTime.diff(run, now, :millisecond)
  end

  defp next_run_on(date) do
    case DateTime.new(date, @run_at, @time_zone) do
      {:ok, run} -> run
      {:gap, _just_before, just_after} -> just_after
      {:ambiguous, first, _second} -> first
    end
  end
end
