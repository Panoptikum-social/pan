defmodule Pan.Parser.AlternateFeed do
  import Ecto.Query
  alias Pan.Repo
  alias PanWeb.AlternateFeed

  def get_or_insert(feed_id, alternate_feed_map) do
    case (from a in AlternateFeed, where: a.feed_id == ^feed_id and
                                          a.url == ^alternate_feed_map[:url],
                                   limit: 1)
         |> Repo.one() do
      nil ->
        %AlternateFeed{feed_id: feed_id}
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