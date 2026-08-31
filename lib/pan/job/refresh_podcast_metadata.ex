defmodule Pan.Job.RefreshPodcastMetadata do
  use GenServer
  require Logger

  # Monthly podcast *metadata* refresh (title, description, image,
  # categories, contributors, feed self-link, ...) — the counterpart to
  # Pan.Job.ImportStalePodcasts, which only ever covers episodes. See
  # backlog.md.
  #
  # Deliberately metadata-only: it calls
  # Pan.Parser.Podcast.update_from_feed/2 with skip_episodes: true, so it
  # never runs Episode.update_from_feed_many/2 — that function prunes
  # episodes no longer present in the feed, which cascades (DB-level
  # ON DELETE CASCADE) into deleting that episode's user likes/comments.
  # Episodes stay solely the responsibility of the safe, additive
  # ImportStalePodcasts job.
  #
  # A strict every-60s tick (not the "drain fast, then back off" pattern
  # ImportStalePodcasts uses) — there's no freshness urgency here, just a
  # monthly cadence driven by each podcast's next_podcast_update.
  @tick_ms 60 * 1000

  # Podcasts refreshed per tick. 33k active podcasts / 30 days / 1440
  # min/day is already ~0.77/min just to keep up on average — 1/tick would
  # leave no headroom for catalog growth and no way to catch up after any
  # downtime. 5/tick keeps the "check every minute" cadence while giving
  # real slack.
  @batch_size 5

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(state) do
    # give app a quiet minute in the beginning
    Process.send_after(self(), :work, @tick_ms)
    {:ok, state}
  end

  @impl true
  def handle_info(:work, state) do
    try do
      PanWeb.Podcast.get_due_for_metadata_refresh(@batch_size)
      |> Enum.each(&refresh_one/1)
    rescue
      error ->
        Logger.error(
          "RefreshPodcastMetadata crashed: " <>
            Exception.format(:error, error, __STACKTRACE__)
        )
    catch
      kind, reason ->
        Logger.error("RefreshPodcastMetadata crashed (#{kind}): #{inspect(reason)}")
    end

    Process.send_after(self(), :work, @tick_ms)
    {:noreply, state}
  end

  defp refresh_one(podcast) do
    case Pan.Parser.Podcast.update_from_feed(podcast, skip_episodes: true) do
      {:ok, _message} ->
        Logger.info("#{podcast.id} ⟳ #{podcast.title}: metadata refreshed")

      {:error, message} ->
        Logger.warning("#{podcast.id} ⟳ #{podcast.title}: metadata refresh failed: #{message}")
    end

    # Reschedule regardless of outcome — no separate failure backoff here,
    # see PanWeb.Podcast.reschedule_metadata_refresh/1.
    PanWeb.Podcast.reschedule_metadata_refresh(podcast)
  end
end
