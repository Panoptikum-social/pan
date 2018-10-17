defmodule Pan.ActivityPub.View do
  use Pan.Web, :view
  alias Pan.ActivityPub.Net


  def published(toot) do
    {:ok, datetime} = toot["published"]
                      |> NaiveDateTime.from_iso8601()
    Timex.format!(datetime, "{ISOdate} {h24}:{m}")
  end


  def content(toot) do
    object = toot["object"]

    if is_binary(object) do
      {:ok, body} = Net.get(object)
      body["content"]
    else
      object["content"]
    end
    |> raw()
  end


  def name(toot, pid) do
    lookup_actor(toot["actor"], pid)["name"]
  end


  def preferred_username(toot, pid) do
    lookup_actor(toot["actor"], pid)["preferredUsername"]
  end


  def actor_image(toot, pid) do
    lookup_actor(toot["actor"], pid)["icon"]["url"]
  end


  defp lookup_actor(url, pid) do
    Agent.get(pid, &Map.get(&1, url)) || put_actor(url, pid)
  end


  defp put_actor(url, pid) do
    {:ok, actor} = Net.get(url)
    Agent.update(pid, &Map.put(&1, url, actor))
    actor
  end
end