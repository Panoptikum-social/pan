defmodule Pan.Parser.Feed do
  use Pan.Web, :controller
  alias Pan.Parser.AlternateFeed

  def get_or_insert(feed_map, podcast_id) do
    case Repo.get_by(Pan.Feed, podcast_id: podcast_id) do
      nil ->
        %Pan.Feed{podcast_id: podcast_id}
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
end