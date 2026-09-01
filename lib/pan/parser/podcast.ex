defmodule Pan.Parser.Podcast do
  alias Pan.Repo
  alias Pan.Parser.{Feed, Language, Persistor, RssFeed}
  alias PanWeb.Podcast
  require Logger
  import Pan.Parser.MyDateTime, only: [now: 0, time_shift: 2]

  # Feed.update_with_redirect_target/2 only refuses a redirect that repeats
  # a target this feed has held before — a server that keeps redirecting to
  # a new, never-before-seen URL (e.g. a cache-busting query string) would
  # otherwise be followed forever. Same cap as the other two feed-redirect
  # paths (RssFeed.initial_import/3, Pan.Updater.Podcast.import_new_episodes/5)
  # — this one was missed in the 2026-08-27 hardening pass and recursed
  # unbounded, seen live hammering a feed several times a second.
  @max_redirects 5

  def get_or_insert(podcast_map) do
    case Repo.get_by(Podcast, title: podcast_map[:title]) do
      nil ->
        %Podcast{
          update_intervall: 10,
          next_update: time_shift(now(), hours: 1),
          next_podcast_update: Podcast.next_metadata_refresh_date(),
          publication_frequency: 0.0,
          subscriptions_count: 0,
          likes_count: 0,
          followers_count: 0,
          episodes_count: 0
        }
        |> Map.merge(podcast_map)
        |> Repo.insert()

      podcast ->
        {:ok, podcast}
    end
  end

  # opts[:skip_episodes]: true skips the episode-pruning step inside
  # Persistor.update_from_feed/3 (which otherwise deletes episodes no longer
  # present in the feed, cascading away any user likes/comments on them —
  # see backlog.md). Used by Pan.Job.RefreshPodcastMetadata for the
  # unattended monthly metadata refresh; the human-triggered callers (admin
  # "update from feed" button, API endpoint, moderation, like/follow/
  # subscribe buttons) keep today's full-resync-with-pruning behavior via
  # the default.
  def update_from_feed(podcast, opts \\ []) do
    update_from_feed(podcast, opts, 0)
  end

  defp update_from_feed(podcast, opts, redirect_count) do
    with {:ok, _} <- update_manually_updated_at(podcast),
         {:ok, _} <- send_download_message(podcast.id),
         {:ok, feed} <- Feed.get_by_podcast_id(podcast.id),
         {:ok, _} <- send_parsing_message(podcast.id),
         {:ok, map} <- RssFeed.import_to_map(feed.self_link_url, podcast.id),
         {:ok, _} <- Persistor.update_from_feed(map, podcast, opts),
         {:ok, _} <- Pan.Updater.Podcast.unpause_and_reset_failure_count(podcast),
         {:ok, _} <- send_final_messages_to_browser(podcast) do
      {:ok, "Podcast data updated"}
    else
      {:redirect, redirect_target} ->
        follow_redirect(podcast, opts, redirect_count, redirect_target)

      {:error, "not found"} ->
        message = "Podcast #{podcast.id} has no feed!"
        Logger.error(message)
        {:error, message}

      {:error, message} ->
        {:error, message}
    end
  end

  defp follow_redirect(podcast, opts, redirect_count, redirect_target) do
    if redirect_count >= @max_redirects do
      Logger.error("Podcast #{podcast.id}: too many redirects")
      {:error, "too many redirects"}
    else
      case Feed.update_with_redirect_target(podcast.id, redirect_target) do
        {:ok, _} -> update_from_feed(podcast, opts, redirect_count + 1)
        {:error, message} -> {:error, message}
      end
    end
  end

  def contributor_import(id) do
    with {:ok, feed} <- Feed.get_by_podcast_id(id),
         {:ok, map} <- RssFeed.import_to_map(feed.self_link_url, id) do
      Persistor.contributor_import(map, id)
      {:ok, "Contributors importet successfully"}
    end
  end

  defp update_manually_updated_at(podcast) do
    Podcast.changeset(podcast, %{manually_updated_at: now()})
    |> Repo.update()
  end

  defp send_download_message(id) do
    Phoenix.PubSub.broadcast(:pan_pubsub, "podcasts:#{id}", %{content: "Downloading Feed"})
    {:ok, :done}
  end

  defp send_parsing_message(id) do
    Phoenix.PubSub.broadcast(:pan_pubsub, "podcasts:#{id}", %{content: "Parsing feed"})
    {:ok, :done}
  end

  defp send_final_messages_to_browser(podcast) do
    Phoenix.PubSub.broadcast(:pan_pubsub, "podcasts:#{podcast.id}", %{
      content: "Finished updating Podcast #{podcast.title}"
    })

    {:ok, :done}
  end

  def fix_owner(id) do
    with {:ok, feed} <- Feed.get_by_podcast_id(id),
         {:ok, map} <- RssFeed.import_to_map(feed.self_link_url, id) do
      Pan.Parser.PodcastContributor.get_or_insert(map[:owner], "owner", id)
      {:ok, "Updated owner successfully for #{id}"}
    end
  end

  def fix_language(podcast) do
    with {:ok, feed} <- Feed.get_by_podcast_id(podcast.id),
         {:ok, map} <- RssFeed.import_to_map(feed.self_link_url, podcast.id) do
      Language.persist_many(map[:languages], podcast)
      {:ok, "Updated owner successfully for #{podcast.title}"}
    else
      {:error, message} ->
        {:error, "#{message} for podcast #{podcast.title}, #{podcast.id}"}
    end
  end
end
