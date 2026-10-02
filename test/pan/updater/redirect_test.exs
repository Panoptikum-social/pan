defmodule Pan.Updater.RedirectTest do
  @moduledoc """
  Redirects during a feed update, against a real local HTTP server
  (TestServer). A redirect target only becomes the feed URL once a feed was
  parsed from it: a temporary redirect to a maintenance page or a homepage
  used to replace working feed URLs for good (wartung.wdr.de,
  app.screencast.com, ...).

  Not async: the SSRF guard has to let localhost through for these tests,
  and the async SSRF guard tests check that it doesn't by default.
  """
  use Pan.DataCase, async: false

  alias PanWeb.{AlternateFeed, Feed, Podcast}
  import Pan.Parser.MyDateTime, only: [now: 0]

  @rss """
  <?xml version="1.0" encoding="UTF-8"?>
  <rss version="2.0">
    <channel>
      <title>Redirect Test Podcast</title>
      <link>https://example.com</link>
      <description>A feed for redirect tests</description>
    </channel>
  </rss>
  """

  @homepage "<!DOCTYPE html><html><body>Welcome to our new website!</body></html>"

  setup do
    Application.put_env(:pan, :ssrf_guard_allowed_hosts, ["localhost"])
    on_exit(fn -> Application.delete_env(:pan, :ssrf_guard_allowed_hosts) end)
    {:ok, _} = TestServer.start()

    podcast =
      %Podcast{}
      |> Podcast.changeset(%{
        title: "Redirect Test Podcast #{System.unique_integer([:positive])}",
        update_intervall: 24,
        next_update: now()
      })
      |> Repo.insert!()

    # no_headers_available skips the HEAD check, so only the GETs under test
    # reach the server
    feed =
      %Feed{podcast_id: podcast.id, no_headers_available: true}
      |> Feed.changeset(%{self_link_url: TestServer.url("/feed.xml")})
      |> Repo.insert!()

    %{podcast: podcast, feed: feed}
  end

  # the plug runs in the server process, so the URL is built up front
  defp redirect(path, to, status \\ 301) do
    location = TestServer.url(to)

    TestServer.add(path,
      via: :get,
      to: fn conn ->
        conn
        |> Plug.Conn.put_resp_header("location", location)
        |> Plug.Conn.resp(status, "")
      end
    )
  end

  defp serve(path, body) do
    TestServer.add(path, via: :get, to: &Plug.Conn.resp(&1, 200, body))
  end

  defp feed_url(feed), do: Repo.get!(Feed, feed.id).self_link_url

  defp alternate_urls(feed) do
    from(a in AlternateFeed, where: a.feed_id == ^feed.id, select: a.url) |> Repo.all()
  end

  describe "Pan.Updater.Podcast.import_new_episodes/4" do
    test "a redirect to a page that isn't a feed leaves the feed URL alone", %{
      podcast: podcast,
      feed: feed
    } do
      redirect("/feed.xml", "/")
      serve("/", @homepage)

      assert {:error, _} = Pan.Updater.Podcast.import_new_episodes(podcast)

      assert feed_url(feed) == TestServer.url("/feed.xml")
      assert alternate_urls(feed) == []
    end

    test "a redirect to a feed moves the feed URL there", %{podcast: podcast, feed: feed} do
      redirect("/feed.xml", "/new-feed.xml")
      serve("/new-feed.xml", @rss)

      assert {:ok, _} = Pan.Updater.Podcast.import_new_episodes(podcast)

      assert feed_url(feed) == TestServer.url("/new-feed.xml")
      assert alternate_urls(feed) == [TestServer.url("/feed.xml")]
    end

    test "a 307 temporary redirect is followed like any other", %{podcast: podcast, feed: feed} do
      redirect("/feed.xml", "/new-feed.xml", 307)
      serve("/new-feed.xml", @rss)

      assert {:ok, _} = Pan.Updater.Podcast.import_new_episodes(podcast)

      assert feed_url(feed) == TestServer.url("/new-feed.xml")
    end

    test "a redirect to the unchanged feed moves the feed URL too", %{
      podcast: podcast,
      feed: feed
    } do
      # a first, regular update stores the feed's hash
      serve("/feed.xml", @rss)
      assert {:ok, _} = Pan.Updater.Podcast.import_new_episodes(podcast)

      redirect("/feed.xml", "/new-feed.xml")
      serve("/new-feed.xml", @rss)

      assert {:ok, message} = Pan.Updater.Podcast.import_new_episodes(podcast)
      assert message =~ "nothing to do"

      assert feed_url(feed) == TestServer.url("/new-feed.xml")
    end
  end

  describe "Pan.Parser.Podcast.update_from_feed/1" do
    test "a redirect to a page that isn't a feed leaves the feed URL alone", %{
      podcast: podcast,
      feed: feed
    } do
      redirect("/feed.xml", "/")
      serve("/", @homepage)

      assert {:error, _} = Pan.Parser.Podcast.update_from_feed(podcast)

      assert feed_url(feed) == TestServer.url("/feed.xml")
      assert alternate_urls(feed) == []
    end

    test "a redirect to a feed moves the feed URL there", %{podcast: podcast, feed: feed} do
      redirect("/feed.xml", "/new-feed.xml")
      serve("/new-feed.xml", @rss)

      assert {:ok, _} = Pan.Parser.Podcast.update_from_feed(podcast)

      assert feed_url(feed) == TestServer.url("/new-feed.xml")
      assert TestServer.url("/feed.xml") in alternate_urls(feed)
    end
  end
end
