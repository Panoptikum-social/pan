defmodule Pan.ActivityPub.View do
  use Pan.Web, :view
  alias Pan.ActivityPub.Net

  def published(toot) do
    {:ok, datetime} =
      toot["published"]
      |> NaiveDateTime.from_iso8601()

    Timex.from_now(datetime)
  end

  def content(%{"object" => object}, pid) when is_binary(object) do
    lookup(object, pid)["content"]
    |> raw()
  end

  def content(%{"object" => object}, _pid) do
    raw(object["content"])
  end

  def name(toot, pid) do
    lookup(toot["actor"], pid)["name"]
  end

  def preferred_username(toot, pid) do
    lookup(toot["actor"], pid)["preferredUsername"]
  end

  def actor_image(toot, pid) do
    lookup(toot["actor"], pid)["icon"]["url"]
  end

  def attributed_to_image(%{"object" => object}, pid) when is_binary(object) do
    attributedTo = lookup(object, pid)["attributedTo"]
    lookup(attributedTo, pid)["icon"]["url"]
  end

  def attributed_to_image(%{"object" => object}, pid) do
    lookup(object["attributedTo"], pid)["icon"]["url"]
  end

  def actor_url(toot, pid) do
    lookup(toot["actor"], pid)["url"]
  end

  def lookup(url, pid) do
    Agent.get(pid, &Map.get(&1, url)) || put(url, pid)
  end

  defp put(url, pid) do
    {:ok, item} = Net.get(url)
    Agent.update(pid, &Map.put(&1, url, item))
    item
  end
end
