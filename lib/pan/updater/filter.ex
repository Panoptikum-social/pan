defmodule Pan.Updater.Filter do
  import Ecto.Query
  alias Pan.Repo
  alias PanWeb.Episode

  def only_new_items_and_new_feed_url(feed_map, podcast_id) do
    known_guids =
      from(e in Episode,
        where: e.podcast_id == ^podcast_id,
        select: e.guid
      )
      |> Repo.all()

    items =
      Quinn.find(feed_map, :item)
      |> Enum.reject(&known_guid?(&1, known_guids))

    new_feed_url = Quinn.find(feed_map, :"new-feed-url")
    itunes_new_feed_url = Quinn.find(feed_map, :"itunes:new-feed-url")

    # Quinn.find/2 returns lists; nested into the result they were skipped by
    # the parser, so <itunes:new-feed-url> never reached the updater
    {:ok, new_feed_url ++ itunes_new_feed_url ++ items}
  end

  defp known_guid?(item, known_guids) do
    case Enum.find(item[:value], &match?(%{name: :guid}, &1)) do
      nil ->
        false

      attribute_map ->
        Map.get(attribute_map, :value)
        |> List.first()
        |> (&Enum.member?(known_guids, &1)).()
    end
  end
end
