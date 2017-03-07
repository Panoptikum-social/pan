defmodule Pan.Parser.AlternateFeed do
  use Pan.Web, :controller

  def get_or_insert(feed_id, alternate_feed_map) do
    case Repo.get_by(Pan.AlternateFeed, feed_id: feed_id,
                                        url: alternate_feed_map[:url]) do
      nil ->
        %Pan.AlternateFeed{feed_id: feed_id}
        |> Map.merge(alternate_feed_map)
        |> Repo.insert()
      alternate_feed ->
        {:ok, alternate_feed}
    end
  end

  def get_or_insert_many(alternate_feeds_map, feed_id) do
    if alternate_feeds_map do
      for {_, alternate_feed_map} <- alternate_feeds_map do
        get_or_insert(feed_id, alternate_feed_map)
      end
    end
  end
end