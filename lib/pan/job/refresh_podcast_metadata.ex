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
    PanWeb.Podcast.get_due_for_metadata_refresh(@batch_size)
    |> Enum.each(&refresh_one_safely/1)

    Process.send_after(self(), :work, @tick_ms)
    {:noreply, state}
  end

  # Isolates each podcast's refresh so one crash doesn't stop the rest of
  # the batch (a single try/rescue used to wrap the whole Enum.each above,
  # which meant podcast 3 of 5 crashing left 4 and 5 unprocessed this
  # tick), and so the failure can be attributed — recorded on the podcast
  # itself and in the Journal, see record_failure/2 — to the specific
  # podcast that caused it, rather than getting lost in a batch-wide log
  # line with no way to tell which podcast triggered it.
  defp refresh_one_safely(podcast) do
    refresh_one(podcast)
  rescue
    error -> handle_crash(podcast, Exception.format(:error, error, __STACKTRACE__))
  catch
    kind, reason -> handle_crash(podcast, "(#{kind}) #{inspect(reason)}")
  end

  defp refresh_one(podcast) do
    case Pan.Parser.Podcast.update_from_feed(podcast, skip_episodes: true) do
      {:ok, _message} ->
        Logger.info("#{podcast.id} ⟳ #{podcast.title}: metadata refreshed")

      {:error, message} ->
        Logger.warning("#{podcast.id} ⟳ #{podcast.title}: metadata refresh failed: #{message}")
        record_failure(podcast, message)
    end

    # Reschedule regardless of outcome — no separate failure backoff here,
    # see PanWeb.Podcast.reschedule_metadata_refresh/1.
    PanWeb.Podcast.reschedule_metadata_refresh(podcast)
  end

  defp handle_crash(podcast, formatted) do
    Logger.error("#{podcast.id} ⟳ #{podcast.title}: RefreshPodcastMetadata crashed: #{formatted}")
    record_failure(podcast, formatted)

    # Still reschedule — a crash shouldn't wedge this podcast out of the
    # monthly cycle any more than a clean failure does, see refresh_one/1.
    PanWeb.Podcast.reschedule_metadata_refresh(podcast)
  end

  # Two complementary, permanent records instead of a log line that
  # scrolls away unread: failure_count/last_error_message on the podcast
  # itself (visible on its own admin row — see
  # PanWeb.Podcast.record_metadata_refresh_failure/2 for why this doesn't
  # also retire the podcast, unlike the episode-update job's mechanism),
  # and a Journal entry for a system-wide, chronological view across every
  # podcast this has ever happened to.
  defp record_failure(podcast, message) do
    PanWeb.Podcast.record_metadata_refresh_failure(podcast, message)

    PanWeb.Journal.log(%{
      module: __MODULE__,
      method: "refresh_one",
      text: "metadata refresh failed for podcast #{podcast.id} (#{podcast.title})",
      before: podcast,
      after: message
    })
  rescue
    # This runs from inside refresh_one_safely/1's own rescue/catch — if
    # recording the failure raised too (seen live: an unbounded-length
    # crash message hitting last_error_message's varchar(255) limit), there
    # is nothing left to catch it, and it takes the whole GenServer down a
    # second time. Never let error-recording itself be a new crash source.
    error ->
      Logger.error(
        "#{podcast.id} ⟳ #{podcast.title}: failed to record failure: " <>
          Exception.format(:error, error, __STACKTRACE__)
      )
  end
end
