defmodule Pan.Parser.PodcastIdentityTest do
  use Pan.DataCase

  alias Pan.Repo
  alias PanWeb.{AlternateFeed, Feed, Podcast}

  defp insert_podcast_with_feed(title, url) do
    podcast =
      Repo.insert!(%Podcast{
        title: title,
        update_intervall: 10,
        next_update: ~N[2026-01-01 00:00:00]
      })

    feed = Repo.insert!(%Feed{podcast_id: podcast.id, self_link_url: url})
    {podcast, feed}
  end

  defp get_or_insert(title, podcast_id, urls),
    do: Pan.Parser.Podcast.get_or_insert(%{title: title}, podcast_id, urls)

  test "a different feed with an existing title becomes a new podcast" do
    {existing, _feed} = insert_podcast_with_feed("Deportes", "https://www.ivoox.com/deportes.xml")

    {:ok, podcast} = get_or_insert("Deportes", nil, ["https://www.rfi.fr/deportes.xml"])

    assert podcast.id != existing.id
    assert podcast.title == "Deportes"
  end

  test "a known feed URL is refused, also with the other scheme" do
    {existing, _feed} =
      insert_podcast_with_feed("Embedded", "https://embedded.fm/episodes?format=rss")

    assert get_or_insert("Other title", nil, ["http://embedded.fm/episodes?format=rss"]) ==
             {:error, {:known_feed, existing.id}}
  end

  test "an alternate feed URL, e.g. from before a redirect, is refused too" do
    {existing, feed} =
      insert_podcast_with_feed("Interface", "https://anchor.fm/s/4c2e2a4c/podcast/rss")

    Repo.insert!(%AlternateFeed{feed_id: feed.id, url: "http://interface.example.com/rss"})

    urls = ["https://new.example.com/rss", "http://interface.example.com/rss"]
    assert get_or_insert("Interface", nil, urls) == {:error, {:known_feed, existing.id}}
  end

  test "a URL that is only part of a known feed URL is no match" do
    insert_podcast_with_feed("Long", "https://anchor.fm/s/528cb318/podcast/rss")

    assert Feed.exact_matching(["https://anchor.fm/s"]) == nil
  end

  test "the refusal names the known podcast" do
    {existing, _feed} = insert_podcast_with_feed("Holding Court", "https://example.com/hc")

    assert Pan.Parser.Podcast.known_feed_message(existing.id) =~
             ~s(podcast #{existing.id} "Holding Court")
  end

  test "following pages of a feed land on the podcast of the first page" do
    {first_page_podcast, _feed} = insert_podcast_with_feed("Paged", "https://example.com/feed")

    assert {:ok, %{id: id}} =
             get_or_insert("Paged", first_page_podcast.id, ["https://example.com/feed?page=2"])

    assert id == first_page_podcast.id
  end
end
