defmodule Pan.ActivityPub.Timeline do
  alias Pan.ActivityPub.{Net, View}

  def toots(url) do
    feeds = %{}

    {:ok, actor} = Net.get_by_address("@informatom@pleroma.panoptikum.io")
    feeds = Map.put(feeds, url, actor)

    {:ok, toot_bodymap} = Net.get(actor["outbox"])

    toot_bodymap["first"]["orderedItems"]
    |> Enum.map(fn(toot) -> to_map(toot, feeds) end)
  end


  defp to_map(toot, feeds) do
    %{published: View.published(toot),
      content:   View.content(toot)}
  end
end