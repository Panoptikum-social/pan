defmodule Pan.ActivityPub.Timeline do
  alias Pan.ActivityPub.{Net, View}

  def toots(url) do
    {:ok, pid} = Agent.start_link(fn -> %{} end)

    {:ok, actor} = Net.get_by_address(url)
    Agent.update(pid, &Map.put(&1, url, actor))

    {:ok, toot_bodymap} = Net.get(actor["outbox"])

    toots =
      if is_binary(toot_bodymap["first"]) do
        View.lookup(toot_bodymap["first"], pid)["orderedItems"]
      else
        toot_bodymap["first"]["orderedItems"]
      end

    if toots != nil do
      Enum.map(toots, fn toot -> to_map(toot, pid) end)
    end
  end

  defp to_map(toot, pid) do
    IO.inspect toot
    %{
      published: View.published(toot),
      content: View.content(toot, pid),
      name: View.name(toot, pid),
      preferred_username: View.preferred_username(toot, pid),
      attributed_to_image: View.attributed_to_image(toot, pid),
      actor_url: View.actor_url(toot, pid),
      boosted: View.boosted(toot),
      attributed_to_name: View.attributed_to_name(toot, pid),
      attributed_to_preferred_username: View.attributed_to_preferred_username(toot, pid),
      attributed_to_url: View.attributed_to_url(toot, pid)
    }
  end
end
