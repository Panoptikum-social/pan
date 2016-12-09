defmodule Pan.Parser.Feed do
  use Pan.Web, :controller

  def find_or_create(feed_map, podcast_id) do
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
            %Pan.AlternateFeed{feed_id: feed.id,
                               title: feed_map[:self_link_url],
                               url: feed_map[:self_link_url]}
            |> Repo.insert()
            {:ok, feed}
        end
    end
  end
end