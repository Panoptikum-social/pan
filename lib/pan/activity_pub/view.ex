defmodule Pan.ActivityPub.View do
  use PanWeb, :view
  alias Pan.ActivityPub.{Net, Timeline, View}

  def widget(url) do
    toots = Timeline.toots(url)
    render(View, "widget.html", toots: toots)
  end

  def published(toot) do
    {:ok, datetime} =
      toot["published"]
      |> NaiveDateTime.from_iso8601()

    Timex.from_now(datetime)
  end

  def content(%{"atomUri" => atom_uri}, pid) when is_binary(atom_uri) do
    lookup(atom_uri, pid)["content"]
    |> raw()
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

  def boosted(toot) do
    toot["type"] == "Announce"
  end

  def attributed_to_image(%{"atomUri" => atom_uri}, pid) when is_binary(atom_uri) do
    attributed_to = lookup(atom_uri, pid)["actor"]
    lookup(attributed_to, pid)["icon"]["url"]
  end

  def attributed_to_image(%{"object" => object}, pid) when is_binary(object) do
    attributed_to = lookup(object, pid)["attributedTo"]
    lookup(attributed_to, pid)["icon"]["url"]
  end

  def attributed_to_image(%{"object" => object}, pid) do
    lookup(object["attributedTo"], pid)["icon"]["url"]
  end

  def attributed_to_name(%{"atomUri" => atom_uri}, pid) when is_binary(atom_uri) do
    attributed_to = lookup(atom_uri, pid)["actor"]
    lookup(attributed_to, pid)["name"]
  end

  def attributed_to_name(%{"object" => object}, pid) when is_binary(object) do
    attributed_to = lookup(object, pid)["attributedTo"]
    lookup(attributed_to, pid)["name"]
  end

  def attributed_to_name(%{"object" => object}, pid) do
    lookup(object["attributedTo"], pid)["name"]
  end

  def attributed_to_preferred_username(%{"atomUri" => atom_uri}, pid) when is_binary(atom_uri) do
    attributed_to = lookup(atom_uri, pid)["actor"]
    lookup(attributed_to, pid)["preferredUsername"]
  end

  def attributed_to_preferred_username(%{"object" => object}, pid) when is_binary(object) do
    attributed_to = lookup(object, pid)["attributedTo"]
    lookup(attributed_to, pid)["preferredUsername"]
  end

  def attributed_to_preferred_username(%{"object" => object}, pid) do
    lookup(object["attributedTo"], pid)["preferredUsername"]
  end

  def attributed_to_url(%{"atomUri" => atom_uri}, pid) when is_binary(atom_uri) do
    attributed_to = lookup(atom_uri, pid)["actor"]
    lookup(attributed_to, pid)["url"]
  end

  def attributed_to_url(%{"object" => object}, pid) when is_binary(object) do
    attributed_to = lookup(object, pid)["attributedTo"]
    lookup(attributed_to, pid)["url"]
  end

  def attributed_to_url(%{"object" => object}, pid) do
    lookup(object["attributedTo"], pid)["url"]
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
