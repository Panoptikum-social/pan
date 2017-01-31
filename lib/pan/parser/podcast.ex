defmodule Pan.Parser.Podcast do
  use Pan.Web, :controller
  alias Pan.Repo
  alias Pan.Parser.RssFeed
  alias Pan.Parser.Persistor
  alias Pan.Podcast
  alias Pan.Feed


  def get_or_insert(podcast_map) do
    case Repo.get_by(Podcast, title: podcast_map[:title]) do
      nil ->
        %Podcast{}
        |> Map.merge(podcast_map)
        |> Repo.insert()
      podcast ->
        {:ok, podcast}
    end
  end


  def delta_import(id) do
    feed = Repo.get_by(Feed, podcast_id: id)

    case RssFeed.import_to_map(feed.self_link_url) do
      {:ok, map}->
        Persistor.delta_import(map, id)
        unpause(id)
        {:ok, "Podcast importet successfully"}

      {:error, message} ->
        unpause(id)
        {:error, message}
    end
  end


  def contributor_import(id) do
    feed = Repo.get_by(Feed, podcast_id: id)

    case RssFeed.import_to_map(feed.self_link_url) do
      {:ok, map}->
        Persistor.contributor_import(map, id)
        {:ok, "Contributors importet successfully"}

      {:error, message} ->
        unpause(id)
        {:error, message}
    end
  end


  def unpause(id) do
    Repo.get!(Pan.Podcast, id)
    |> Pan.Podcast.changeset(%{ update_paused: false })
    |> Repo.update([force: true])
  end


  def fix_owner(id) do
    feed = Repo.get_by(Feed, podcast_id: id)

    case RssFeed.import_to_map(feed.self_link_url) do
      {:ok, map}->
        Pan.Parser.Owner.get_or_insert(map[:owner], id)
        {:ok, "Updated owner successfully"}
      {:error, message} ->
        {:error, message}
    end
  end
end