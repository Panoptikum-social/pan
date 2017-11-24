defmodule Pan.Parser.Podcast do
  use Pan.Web, :controller
  alias Pan.Repo
  alias Pan.Parser.RssFeed
  alias Pan.Parser.Persistor
  alias Pan.Parser.Language
  alias Pan.Parser.Feed
  alias PanWeb.Podcast
  require Logger


  def get_or_insert(podcast_map) do
    case Repo.get_by(Podcast, title: podcast_map[:title]) do
      nil ->
        %Podcast{update_intervall: 1,
                 next_update: Timex.shift(Timex.now(), hours: 1),
                 publication_frequency: 0.0,
                 subscriptions_count: 0,
                 likes_count: 0,
                 followers_count: 0,
                 episodes_count: 0}
        |> Map.merge(podcast_map)
        |> Repo.insert()
      podcast ->
        {:ok, podcast}
    end
  end


  def update(podcast_map, podcast_id) do
    Repo.get(Podcast, podcast_id)
    |> Podcast.changeset(podcast_map)
    |> Repo.update()
  end


  def delta_import(id) do
    with {:ok, feed} <- Feed.get_by_podcast_id(id),
         {:ok, map} <- RssFeed.import_to_map(feed.self_link_url, id),
         {:ok, _} <- Persistor.delta_import(map, id),
         {:ok, _} <- unpause_and_reset_failure_count(id) do
      {:ok, "Podcast importet"}

    else
      {:redirect, redirect_target} ->
        Feed.update_with_redirect_target(id, redirect_target)
        delta_import(id)

      {:error, :not_found} ->
        increase_failure_count(id)
        message = "=== Podcast #{inspect id} has no feed! ==="
        Logger.error(message)
        {:error, message}

      {:error, message} ->
        increase_failure_count(id)
        {:error, message}
    end
  end


  def update_from_feed(id) do
    with {:ok, _} <- send_download_message(id),
         {:ok, feed} <- Feed.get_by_podcast_id(id),
         {:ok, _} <- send_parsing_message(id),
         {:ok, map} <- RssFeed.import_to_map(feed.self_link_url, id),
         {:ok, _} <- Persistor.update_from_feed(map, id),
         {:ok, _} <- unpause_and_reset_failure_count(id),
         {:ok, _} <- send_final_messages_to_browser(id) do
      {:ok, "Podcast data updated"}

    else
      {:redirect, redirect_target} ->
        Feed.update_with_redirect_target(id, redirect_target)
        delta_import(id)

      {:error, :not_found} ->
        message = "=== Podcast #{inspect id} has no feed! ==="
        Logger.error(message)
        {:error, message}

      {:error, message} ->
        {:error, message}
    end
  end

  def contributor_import(id) do
    with {:ok, feed} <- Feed.get_by_podcast_id(id),
         {:ok, map} <- RssFeed.import_to_map(feed.self_link_url) do
      Persistor.contributor_import(map, id)
      {:ok, "Contributors importet successfully"}
    end
  end


  def unpause_and_reset_failure_count(id) do
    Podcast
    |> Repo.get(id)
    |> PanWeb.Podcast.changeset(%{update_paused: false, failure_count: 0})
    |> Repo.update([force: true])
  end


  def send_download_message(id) do
      PanWeb.Endpoint.broadcast("podcasts:" <> Integer.to_string(id),
                                "notification", %{content: "<i class='fa fa-download'></i> ...", type: "success"})
      {:ok, "nothing to do"}
  end


  def send_parsing_message(id) do
      PanWeb.Endpoint.broadcast("podcasts:" <> Integer.to_string(id),
                                "notification", %{content: "<i class='fa fa-feed'></i> ...", type: "success"})
      {:ok, "nothing to do"}
  end


  def send_final_messages_to_browser(id) do
    podcast = Repo.get(Podcast, id)
    notification =
      %{content: "<i class='fa fa-refresh'></i> " <> Integer.to_string(id) <>
                  " <i class='fa fa-podcast'></i> " <> podcast.title,
        type: "info"}

    PanWeb.Endpoint.broadcast("podcasts:" <> Integer.to_string(podcast.id),
                              "notification", notification)

    notification =
      %{content: "You want to refresh your browser window now [F5]!",
        type: "warning"}
    PanWeb.Endpoint.broadcast("podcasts:" <> Integer.to_string(podcast.id),
                              "notification", notification)
    {:ok, "nothing to do"}
  end


  def increase_failure_count(id) do
    podcast = Repo.get(Podcast, id)

    podcast
    |> Podcast.changeset(%{failure_count: (podcast.failure_count || 0) + 1})
    |> Repo.update([force: true])

    if podcast.failure_count == 9 do
      podcast
      |> Podcast.changeset(%{retired: true})
      |> Repo.update([force: true])
    end
  end


  def fix_owner(id) do
    with {:ok, feed} <- Feed.get_by_podcast_id(id),
         {:ok, map} <- RssFeed.import_to_map(feed.self_link_url) do
      Pan.Parser.PodcastContributor.get_or_insert(map[:owner], "owner", id)
      {:ok, "Updated owner successfully for #{id}"}
    end
  end


  def fix_language(podcast) do
    with {:ok, feed} <- Feed.get_by_podcast_id(podcast.id),
         {:ok, map} <- RssFeed.import_to_map(feed.self_link_url) do
      Language.persist_many(map[:languages], podcast)
      {:ok, "Updated owner successfully for #{podcast.title}"}

    else
      {:error, message} ->
        {:error, message <> " for podcast #{podcast.title}, #{podcast.id}"}
    end
  end
end
