defmodule Pan.Updater.SuccessionTest do
  @moduledoc """
  A feed that redirects to (or announces) a different show must not fill
  the old podcast with the new show's episodes, see Pan.Updater.Succession.
  Against a real local HTTP server (TestServer), not async for the SSRF
  guard, like Pan.Updater.RedirectTest.
  """
  use Pan.DataCase, async: false

  import ExUnit.CaptureLog
  import Pan.Parser.MyDateTime, only: [now: 0]
  alias PanWeb.{Episode, Feed, FeedBacklog, Podcast}

  setup do
    Application.put_env(:pan, :ssrf_guard_allowed_hosts, ["localhost"])
    on_exit(fn -> Application.delete_env(:pan, :ssrf_guard_allowed_hosts) end)
    {:ok, _} = TestServer.start()

    podcast =
      Repo.insert!(%Podcast{
        title: "Holding Court",
        update_intervall: 24,
        next_update: now(),
        failure_count: 0
      })

    # no_headers_available skips the HEAD check
    feed =
      Repo.insert!(%Feed{
        podcast_id: podcast.id,
        no_headers_available: true,
        self_link_url: TestServer.url("/feed.xml")
      })

    for title <- ["Old 1", "Old 2", "Old 3", "Old 4"] do
      Repo.insert!(%Episode{podcast_id: podcast.id, title: title, guid: "guid-" <> title})
    end

    %{podcast: podcast, feed: feed}
  end

  defp rss(title, episode_titles, extra \\ "") do
    items =
      for episode_title <- episode_titles do
        """
        <item>
          <title>#{episode_title}</title>
          <guid>guid-#{episode_title}</guid>
          <pubDate>Sat, 01 Apr 2023 19:00:00 GMT</pubDate>
          <enclosure url="https://example.com/#{URI.encode(episode_title)}.mp3" length="1" type="audio/mpeg"/>
        </item>
        """
      end

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd">
      <channel>
        <title>#{title}</title>
        <link>https://example.com</link>
        <description>A feed for succession tests</description>
        #{extra}
        #{Enum.join(items)}
      </channel>
    </rss>
    """
  end

  defp redirect(path, to) do
    location = TestServer.url(to)

    TestServer.add(path,
      via: :get,
      to: fn conn ->
        conn |> Plug.Conn.put_resp_header("location", location) |> Plug.Conn.resp(301, "")
      end
    )
  end

  defp serve(path, body), do: TestServer.add(path, via: :get, to: &Plug.Conn.resp(&1, 200, body))

  defp feed_url(feed), do: Repo.get!(Feed, feed.id).self_link_url
  defp backlog_urls, do: from(b in FeedBacklog, select: b.url) |> Repo.all()

  defp episode_titles(podcast) do
    from(e in Episode, where: e.podcast_id == ^podcast.id, select: e.title) |> Repo.all()
  end

  describe "a redirect in the episode updater" do
    test "to a different show is not followed, the new feed goes into the backlog", %{
      podcast: podcast,
      feed: feed
    } do
      redirect("/feed.xml", "/sixers.xml")
      serve("/sixers.xml", rss("Sixers Talk", ["New 1", "New 2", "New 3", "New 4"]))

      assert {:ok, _message} = Pan.Updater.Podcast.import_new_episodes(podcast)

      assert feed_url(feed) == TestServer.url("/feed.xml")
      assert TestServer.url("/sixers.xml") in backlog_urls()
      refute "New 1" in episode_titles(podcast)

      podcast = Repo.get!(Podcast, podcast.id)
      assert podcast.last_error_message =~ "different show"
      assert podcast.failure_count == 0
      refute podcast.retired
    end

    test "to the renamed show with known episodes is followed", %{podcast: podcast, feed: feed} do
      redirect("/feed.xml", "/renamed.xml")
      serve("/renamed.xml", rss("Holding Court Daily", ["Old 1", "Old 2", "Old 3", "New 1"]))

      assert {:ok, _message} = Pan.Updater.Podcast.import_new_episodes(podcast)

      assert feed_url(feed) == TestServer.url("/renamed.xml")
      assert "New 1" in episode_titles(podcast)
      assert backlog_urls() == []
    end

    test "with an unclear result is not followed and reported once", %{
      podcast: podcast,
      feed: feed
    } do
      redirect("/feed.xml", "/unclear.xml")
      # 1 of 4 known: between 10 % and 50 %
      serve("/unclear.xml", rss("Something Else", ["Old 1", "New 1", "New 2", "New 3"]))

      log = capture_log(fn -> Pan.Updater.Podcast.import_new_episodes(podcast) end)
      assert log =~ "ReviewNeeded"
      assert feed_url(feed) == TestServer.url("/feed.xml")
      assert backlog_urls() == []

      # the test server answers each route once
      redirect("/feed.xml", "/unclear.xml")
      serve("/unclear.xml", rss("Something Else", ["Old 1", "New 1", "New 2", "New 3"]))

      again =
        capture_log(fn ->
          Pan.Updater.Podcast.import_new_episodes(Repo.get!(Podcast, podcast.id), true)
        end)

      refute again =~ "ReviewNeeded"
    end
  end

  describe "<itunes:new-feed-url> in the episode updater" do
    test "announcing a different show is not saved, the own new episodes still come", %{
      podcast: podcast,
      feed: feed
    } do
      new_feed_url = TestServer.url("/sixers.xml")

      serve(
        "/feed.xml",
        rss(
          "Holding Court",
          ["Old 1", "Last 1"],
          "<itunes:new-feed-url>#{new_feed_url}</itunes:new-feed-url>"
        )
      )

      serve("/sixers.xml", rss("Sixers Talk", ["New 1", "New 2", "New 3", "New 4"]))

      assert {:ok, _message} = Pan.Updater.Podcast.import_new_episodes(podcast)

      assert feed_url(feed) == TestServer.url("/feed.xml")
      assert "Last 1" in episode_titles(podcast)
      assert new_feed_url in backlog_urls()
    end

    test "announcing a page that isn't a feed is not saved", %{podcast: podcast, feed: feed} do
      new_feed_url = TestServer.url("/landing")

      serve(
        "/feed.xml",
        rss(
          "Holding Court",
          ["Old 1"],
          "<itunes:new-feed-url>#{new_feed_url}</itunes:new-feed-url>"
        )
      )

      serve("/landing", "<!DOCTYPE html><html><body>Welcome to Screencast</body></html>")

      assert {:ok, _message} = Pan.Updater.Podcast.import_new_episodes(podcast)

      assert feed_url(feed) == TestServer.url("/feed.xml")
      assert backlog_urls() == []
    end

    test "announcing the same show at a new address is saved", %{podcast: podcast, feed: feed} do
      new_feed_url = TestServer.url("/moved.xml")

      serve(
        "/feed.xml",
        rss(
          "Holding Court",
          ["Old 1"],
          "<itunes:new-feed-url>#{new_feed_url}</itunes:new-feed-url>"
        )
      )

      serve("/moved.xml", rss("Holding Court", ["Old 1", "Old 2", "Old 3"]))

      assert {:ok, _message} = Pan.Updater.Podcast.import_new_episodes(podcast)

      assert feed_url(feed) == new_feed_url
      assert backlog_urls() == []
    end
  end

  test "the metadata refresh refuses a redirect to a different show", %{
    podcast: podcast,
    feed: feed
  } do
    redirect("/feed.xml", "/sixers.xml")
    serve("/sixers.xml", rss("Sixers Talk", ["New 1", "New 2", "New 3", "New 4"]))

    assert {:error, message} = Pan.Parser.Podcast.update_from_feed(podcast, skip_episodes: true)
    assert message =~ "a different show"
    assert feed_url(feed) == TestServer.url("/feed.xml")
    assert Repo.get!(Podcast, podcast.id).title == "Holding Court"
  end
end
