defmodule Pan.Parser.AlternateFeed do
  use Pan.Web, :controller

  def find_or_create_many(alternate_feeds_map, feed_id) do
    for {_, alternate_feed_map} <- alternate_feeds_map do
      case Repo.get_by(Pan.AlternateFeed, url: alternate_feed_map[:url]) do
        nil ->
          %Pan.AlternateFeed{feed_id: feed_id}
          |> Map.merge(alternate_feed_map)
          |> Repo.insert()
        alternate_feed ->
          {:ok, alternate_feed}
      end
    end
  end
end