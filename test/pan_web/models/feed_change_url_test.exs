defmodule PanWeb.FeedChangeUrlTest do
  use Pan.DataCase

  alias Pan.Repo
  alias PanWeb.{AlternateFeed, Feed, Podcast}

  defp insert_feed(url) do
    podcast =
      Repo.insert!(%Podcast{
        title: "Show",
        update_intervall: 10,
        next_update: ~N[2030-01-01 00:00:00]
      })

    Repo.insert!(%Feed{podcast_id: podcast.id, self_link_url: url, hash: "abc", etag: "e1"})
  end

  defp alternate_urls(feed) do
    from(a in AlternateFeed, where: a.feed_id == ^feed.id, select: a.url, order_by: a.url)
    |> Repo.all()
  end

  test "change_url keeps the old URL, resets caching and makes the podcast due" do
    feed = insert_feed("https://old.example.com/feed")

    assert {:ok, changed} = Feed.change_url(feed, "https://new.example.com/feed")

    assert changed.self_link_url == "https://new.example.com/feed"
    assert is_nil(changed.hash) and is_nil(changed.etag)
    assert alternate_urls(feed) == ["https://old.example.com/feed"]

    assert NaiveDateTime.compare(
             Repo.get!(Podcast, feed.podcast_id).next_update,
             ~N[2030-01-01 00:00:00]
           ) ==
             :lt
  end

  test "restore_alternate only takes one of the feed's alternate URLs" do
    feed = insert_feed("https://new.example.com/feed")
    Repo.insert!(%AlternateFeed{feed_id: feed.id, url: "https://old.example.com/feed"})

    assert {:error, _message} = Feed.restore_alternate(feed, "https://other.example.com/feed")

    assert {:ok, restored} = Feed.restore_alternate(feed, "https://old.example.com/feed")
    assert restored.self_link_url == "https://old.example.com/feed"
    assert "https://new.example.com/feed" in alternate_urls(feed)
  end
end
