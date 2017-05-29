defmodule Pan.Parser.Podcast do
  use Pan.Web, :controller
  alias Pan.Repo
  alias Pan.Parser.RssFeed
  alias Pan.Parser.Persistor
  alias Pan.Parser.AlternateFeed
  alias Pan.Parser.Language
  alias Pan.Podcast
  alias Pan.Feed
  require Logger


  def get_or_insert(podcast_map) do
    case Repo.get_by(Podcast, title: podcast_map[:title]) do
      nil ->
        %Podcast{update_intervall: 1,
                 next_update: Timex.shift(Timex.now(), hours: 1)}
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
        unpause(id)
        {:ok, "Podcast importet"}

      {:redirect, redirect_target} ->
        if String.starts_with?(redirect_target, "http") do
          AlternateFeed.get_or_insert(feed.id, %{url: feed.self_link_url,
                                                 title: feed.self_link_url})

          Feed.changeset(feed, %{self_link_url: redirect_target})
          |> Repo.update([force: true])
        end

        # Now that we have updated Feed and alternate feed, let's try again
        delta_import(id)

      {:error, message} -> {:error, message}
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