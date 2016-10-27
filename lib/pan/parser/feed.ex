defmodule Pan.Parser.Feed do
  use Pan.Web, :controller

  def find_or_create(feed_map, podcast_id) do
    case Repo.get_by(Pan.Feed, self_link_url: feed_map[:self_link_url]) do
      nil ->
        %Pan.Feed{podcast_id: podcast_id}
        |> Map.merge(feed_map)
        |> Repo.insert()
      feed ->
        {:ok, feed}
    end
  end
end