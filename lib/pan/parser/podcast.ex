defmodule Pan.Parser.Podcast do
  use Pan.Web, :controller
  alias Pan.Repo
  alias Pan.Parser.RssFeed
  alias Pan.Parser.Persistor
  alias Pan.Parser.AlternateFeed
  alias Pan.Parser.Language
  alias PanWeb.Podcast
  alias PanWeb.Feed
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


  def delta_import(id) do
    feed = Repo.get_by(Feed, podcast_id: id)

    unless feed do
      Logger.error "=== Podcast #{inspect id} has no feed! ==="
    end

    case RssFeed.import_to_map(feed.self_link_url, id) do
      {:ok, map} ->
        Persistor.delta_import(map, id)
        unpause_and_reset_failure_count(id)
        {:ok, "Podcast importet"}

      {:redirect, redirect_target} ->
        AlternateFeed.get_or_insert(feed.id, %{url: feed.self_link_url,
                                               title: feed.self_link_url})

        Feed.changeset(feed, %{self_link_url: redirect_target})
        |> Repo.update([force: true])

        # Now that we have updated Feed and alternate feed, let's try again
        delta_import(id)

      {:error, message} ->
        increase_failure_count(id)
        {:error, message}
    end
  end


  def contributor_import(id) do
    feed = Repo.get_by(Feed, podcast_id: id)

    case RssFeed.import_to_map(feed.self_link_url) do
      {:ok, map} ->
        Persistor.contributor_import(map, id)
        {:ok, "Contributors importet successfully"}

      {:error, message} ->
        {:error, message}
    end
  end


  def unpause_and_reset_failure_count(id) do
    Repo.get(Podcast, id)
    |> PanWeb.Podcast.changeset(%{update_paused: false,
                                  failure_count: 0})
    |> Repo.update([force: true])
  end


  def increase_failure_count(id) do
    podcast = Repo.get(Podcast, id)

    Podcast.changeset(podcast, %{failure_count: (podcast.failure_count || 0) + 1})
    |> Repo.update([force: true])

    if podcast.failure_count == 9 do
      Podcast.changeset(podcast, %{retired: true})
      |> Repo.update([force: true])
    end
  end


  def fix_owner(id) do
    feed = Repo.get_by(Feed, podcast_id: id)

    case RssFeed.import_to_map(feed.self_link_url) do
      {:ok, map} ->
        Pan.Parser.Owner.get_or_insert(map[:owner], id)
        {:ok, "Updated owner successfully for #{id}"}
      {:error, message} ->
        {:error, message}
    end
  end


  def fix_language(podcast) do
    feed = Repo.get_by(Feed, podcast_id: podcast.id)

    case RssFeed.import_to_map(feed.self_link_url) do
      {:ok, map} ->
        Language.persist_many(map[:languages], podcast)
        {:ok, "Updated owner successfully for #{podcast.title}"}
      {:error, message} ->
        {:error, message <> " for podcast #{podcast.title}, #{podcast.id}"}
    end
  end
end