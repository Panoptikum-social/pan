defmodule Pan.Parser.Podcast do
  use Pan.Web, :controller
  alias Pan.Repo
  alias Pan.Parser.RssFeed
  alias Pan.Parser.Persistor
  alias Pan.Parser.AlternateFeed
  alias Pan.Podcast
  alias Pan.Feed
  require Logger


  def get_or_insert(podcast_map) do
    case Repo.get_by(Podcast, title: podcast_map[:title]) do
      nil ->
        %Podcast{update_intervall: 1,
                 next_update: "2010-04-17 14:00:00"}
        |> Map.merge(podcast_map)
        |> Repo.insert()
      podcast ->
        {:ok, podcast}
    end
  end


  def delta_import(id) do
    feed = Repo.get_by(Feed, podcast_id: id)

    unless feed do
      Logger.error "Podcast " <> Integer.to_string(id) <> " has no feed"
    end

    case RssFeed.import_to_map(feed.self_link_url) do
      {:ok, map} ->
        Persistor.delta_import(map, id)
        unpause(id)
        {:ok, "Podcast importet successfully"}

      {:redirect, redirect_target} ->
        AlternateFeed.get_or_insert(feed.id, %{url: feed.self_link_url})

        Feed.changeset(feed, %{self_link_url: redirect_target})
        |> Repo.update([force: true])
        # Now that we have updated Feed and alternate feed, let's try again
        delta_import(id)

      {:error, message} ->
        unpause(id)
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
        unpause(id)
        {:error, message}
    end
  end


  def unpause(id) do
    Repo.get!(Pan.Podcast, id)
    |> Pan.Podcast.changeset(%{update_paused: false})
    |> Repo.update([force: true])
  end


  def fix_owner(id) do
    feed = Repo.get_by(Feed, podcast_id: id)

    case RssFeed.import_to_map(feed.self_link_url) do
      {:ok, map} ->
        Pan.Parser.Owner.get_or_insert(map[:owner], id)
        {:ok, "Updated owner successfully"}
      {:error, message} ->
        {:error, message}
    end
  end
end