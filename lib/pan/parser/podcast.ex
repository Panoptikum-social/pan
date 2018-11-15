defmodule Pan.Parser.Podcast do
  alias Pan.Repo
  alias Pan.Parser.{Feed, Language, Persistor, RssFeed}
  alias PanWeb.Podcast
  require Logger
  import Pan.Parser.Helpers, only: [now: 0]

  def get_or_insert(podcast_map) do
    case Repo.get_by(Podcast, title: podcast_map[:title]) do
      nil ->
        %Podcast{
          update_intervall: 10,
          next_update: Timex.shift(now(), hours: 1),
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

  def update_from_feed(podcast) do
    with {:ok, _} <- send_download_message(podcast.id),
         {:ok, feed} <- Feed.get_by_podcast_id(podcast.id),
         {:ok, _} <- send_parsing_message(podcast.id),
         {:ok, map} <- RssFeed.import_to_map(feed.self_link_url, podcast.id),
         {:ok, _} <- Persistor.update_from_feed(map, podcast),
         {:ok, _} <- Pan.Updater.Podcast.unpause_and_reset_failure_count(podcast),
         {:ok, _} <- send_final_messages_to_browser(podcast) do
      {:ok, "Podcast data updated"}
    else
      {:redirect, redirect_target} ->
        Feed.update_with_redirect_target(podcast.id, redirect_target)
        update_from_feed(podcast)

      {:error, "not found"} ->
        message = "=== Podcast #{podcast.id} has no feed! ==="
        Logger.error(message)
        {:error, message}

      {:error, message} ->
        {:error, message}
    end
  end

  def contributor_import(id) do
    with {:ok, feed} <- Feed.get_by_podcast_id(id),
         {:ok, map} <- RssFeed.import_to_map(feed.self_link_url, id) do
      Persistor.contributor_import(map, id)
      {:ok, "Contributors importet successfully"}
    end
  end

  defp send_download_message(id) do
    PanWeb.Endpoint.broadcast("podcasts:#{id}", "notification", %{
      content: "<i class='fa fa-download'></i> ...",
      type: "success"
    })

    {:ok, :done}
  end

  defp send_parsing_message(id) do
    PanWeb.Endpoint.broadcast("podcasts:#{id}", "notification", %{
      content: "<i class='fa fa-feed'></i> ...",
      type: "success"
    })

    {:ok, :done}
  end

  defp send_final_messages_to_browser(podcast) do
    PanWeb.Endpoint.broadcast("podcasts:#{podcast.id}", "notification", %{
      content:
        "<i class='fa fa-refresh'></i> #{podcast.id} " <>
          "<i class='fa fa-podcast'></i> #{podcast.title}",
      type: "info"
    })

    PanWeb.Endpoint.broadcast("podcasts:#{podcast.id}", "notification", %{
      content: "You want to refresh your browser window now [F5]!",
      type: "warning"
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
