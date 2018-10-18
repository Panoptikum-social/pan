defmodule Pan.ActivityPub.Timeline do
  alias Pan.ActivityPub.{Net, View}

  def toots(url) do
    {:ok, pid} = Agent.start_link(fn -> %{} end)

    {:ok, actor} = Net.get_by_address("@informatom@pleroma.panoptikum.io")
    Agent.update(pid, &Map.put(&1, url, actor))

    {:ok, toot_bodymap} = Net.get(actor["outbox"])

    toot_bodymap["first"]["orderedItems"]
    |> Enum.map(fn(toot) -> to_map(toot, pid) end)
  end


  defp to_map(toot, pid) do
    %{published:           View.published(toot),
      content:             View.content(toot, pid),
      name:                View.name(toot, pid),
      preferred_username:  View.preferred_username(toot, pid),
      attributed_to_image: View.attributed_to_image(toot, pid),
      actor_url:           View.actor_url(toot, pid)}
  end
end