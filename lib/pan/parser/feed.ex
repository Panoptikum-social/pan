defmodule Pan.Parser.Feed do
  use Pan.Web, :controller
  alias Pan.Parser.AlternateFeed
  alias PanWeb.Feed
  alias Pan.Repo

  def get_or_insert(feed_map, podcast_id) do
    case Repo.get_by(Feed, podcast_id: podcast_id) do
      nil ->
        %Feed{podcast_id: podcast_id}
        |> Map.merge(feed_map)
        |> Repo.insert()
      feed ->
        case feed.self_link_url == feed_map[:self_link_url] do
          true ->
            {:ok, feed}
          false ->
            AlternateFeed.get_or_insert(feed.id, %{url:   feed_map[:self_link_url],
                                                   title: feed_map[:self_link_url]})
            {:ok, feed}
        end
    end
  end


  def update_with_redirect_target(id, redirect_target) do
    {:ok, feed} = get_by_podcast_id(id)

    if String.starts_with?(redirect_target, "http") do
      AlternateFeed.get_or_insert(feed.id, %{url: feed.self_link_url,
                                             title: feed.self_link_url})
      feed
      |> Feed.changeset(%{self_link_url: redirect_target})
      |> Repo.update([force: true])
    end
  end


  def get_by_podcast_id(id) do
    case Repo.get_by(Feed, podcast_id: id) do
      nil ->
        {:error, :not_found}
      feed ->
        {:ok, feed}
    end
  end
end