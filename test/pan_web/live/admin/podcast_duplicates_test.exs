defmodule PanWeb.Live.Admin.PodcastDuplicatesTest do
  use PanWeb.ConnCase

  import Ecto.Query
  import Phoenix.LiveViewTest
  alias Pan.Repo
  alias PanWeb.{AlternateFeed, Feed, Podcast, User}

  defp insert_user(attrs) do
    n = System.unique_integer([:positive])

    %User{name: "Test", username: "dup_#{n}", email: "dup_#{n}@example.com"}
    |> struct(attrs)
    |> Repo.insert!()
  end

  defp insert_podcast(title, url, attrs \\ []) do
    podcast =
      %Podcast{title: title, update_intervall: 10, next_update: ~N[2026-01-01 00:00:00]}
      |> struct(attrs)
      |> Repo.insert!()

    feed = Repo.insert!(%Feed{podcast_id: podcast.id, self_link_url: url})
    {podcast, feed}
  end

  defp eventually(check, tries \\ 50) do
    cond do
      check.() ->
        true

      tries == 0 ->
        false

      true ->
        Process.sleep(20)
        eventually(check, tries - 1)
    end
  end

  defp as(conn, user), do: init_test_session(conn, %{"user_id" => user.id, "admin" => user.admin})

  test "lists each kind of candidate", %{conn: conn} do
    insert_podcast("Double import", "https://example.com/double.xml")
    insert_podcast("Double import again", "http://example.com/double.xml")
    insert_podcast("Deportes", "https://www.ivoox.com/deportes.xml")
    insert_podcast("deportes ", "https://www.rfi.fr/deportes.xml")
    {_old, old_feed} = insert_podcast("Moved show", "https://new.example.com/feed")
    Repo.insert!(%AlternateFeed{feed_id: old_feed.id, url: "https://old.example.com/feed"})
    insert_podcast("Stale copy", "https://old.example.com/feed")

    insert_podcast("Holding Court", "https://example.com/hc.xml",
      last_error_message: "Feed now delivers a different show (0 % of its episodes known): x"
    )

    conn = as(conn, insert_user(admin: true))

    for {tab, expected} <- [
          {"different_show", "0 % of its episodes known"},
          {"same_feed_url", "Double import again"},
          {"same_title", "0 identical episode titles"},
          {"alternate", "Stale copy"}
        ] do
      {:ok, view, _html} = live(conn, "/admin/podcasts/duplicates?tab=#{tab}")
      assert render_async(view) =~ expected
    end

    {:ok, view, _html} = live(conn, "/admin/podcasts/duplicates?tab=alternate")
    html = render_async(view)
    assert html =~ "old.example.com/feed"
    assert html =~ "0 identical episode titles"
    # "Moved show" has the URL in its history, "Stale copy" uses it
    assert html =~ ~r/has the URL in its history.*Moved show.*uses it as feed URL.*Stale copy/s
  end

  test "retires a podcast", %{conn: conn} do
    {podcast, _feed} = insert_podcast("Dead", "https://www.podomatic.com/404.html")
    {:ok, view, _html} = live(as(conn, insert_user(admin: true)), "/admin/podcasts/duplicates")

    assert render_click(view, "retire", %{"id" => podcast.id}) =~ "retired"
    assert Repo.get!(Podcast, podcast.id).retired
    # the lists reload after an action
    render_async(view)
  end

  test "restores a previous feed URL and keeps the current one", %{conn: conn} do
    {podcast, feed} = insert_podcast("Moved away", "https://www.podomatic.com/404.html")
    Repo.update!(Ecto.Changeset.change(feed, hash: "abc", etag: "x"))
    Repo.insert!(%AlternateFeed{feed_id: feed.id, url: "https://show.example.com/feed"})
    {:ok, view, _html} = live(as(conn, insert_user(admin: true)), "/admin/podcasts/duplicates")

    render_submit(view, "restore", %{
      "feed_id" => feed.id,
      "url" => "https://show.example.com/feed"
    })

    feed = Repo.get!(Feed, feed.id)
    assert feed.self_link_url == "https://show.example.com/feed"
    assert feed.hash == nil and feed.etag == nil

    assert Repo.exists?(
             from(a in AlternateFeed,
               where: a.feed_id == ^feed.id and a.url == "https://www.podomatic.com/404.html"
             )
           )

    assert Repo.get!(Podcast, podcast.id).next_update != ~N[2026-01-01 00:00:00]
    render_async(view)
  end

  test "restores only one of the feed's own previous URLs", %{conn: conn} do
    {_podcast, feed} = insert_podcast("Moved away", "https://www.podomatic.com/404.html")
    {:ok, view, _html} = live(as(conn, insert_user(admin: true)), "/admin/podcasts/duplicates")

    html =
      render_submit(view, "restore", %{"feed_id" => feed.id, "url" => "https://evil.example.com"})

    assert html =~ "is not an alternate feed"
    assert Repo.get!(Feed, feed.id).self_link_url == "https://www.podomatic.com/404.html"
    render_async(view)
  end

  test "switches tabs and falls back to the first one", %{conn: conn} do
    insert_podcast("Double import", "https://example.com/double.xml")
    insert_podcast("Double import again", "http://example.com/double.xml")

    {:ok, view, _html} =
      live(as(conn, insert_user(admin: true)), "/admin/podcasts/duplicates?tab=nonsense")

    assert render_async(view) =~ "Feed delivers a different show"

    view |> element("a[role=tab]", "Same feed URL") |> render_click()
    assert_patch(view, "/admin/podcasts/duplicates?tab=same_feed_url")
    assert render_async(view) =~ "Double import again"
  end

  test "merges one podcast of a group into another", %{conn: conn} do
    {keep, _} = insert_podcast("Double import", "https://example.com/double.xml")
    {merged, _} = insert_podcast("Double import again", "http://example.com/double.xml")

    {:ok, view, _html} =
      live(as(conn, insert_user(admin: true)), "/admin/podcasts/duplicates?tab=same_feed_url")

    assert render_async(view) =~ "Merge into"

    html = render_submit(view, "merge", %{"from_id" => "#{merged.id}", "to_id" => "#{keep.id}"})
    assert html =~ "Merging podcast #{merged.id} into #{keep.id}"

    # the merge runs in a task of its own and reports back when done
    assert eventually(fn -> render(view) =~ "merged into #{keep.id}" end)
    refute Repo.get(Podcast, merged.id)
    render_async(view)
  end

  test "deletes alternate feeds by URL across all podcasts", %{conn: conn} do
    {_a, feed_a} = insert_podcast("A", "https://a.example.com/feed")
    {_b, feed_b} = insert_podcast("B", "https://b.example.com/feed")
    Repo.insert!(%AlternateFeed{feed_id: feed_a.id, url: "https://www.podomatic.com/404.html"})
    Repo.insert!(%AlternateFeed{feed_id: feed_b.id, url: "http://www.podomatic.com/404.html"})

    Repo.insert!(%AlternateFeed{
      feed_id: feed_b.id,
      url: "https://www.podomatic.com/404.html?x=1"
    })

    {:ok, view, html} =
      live(as(conn, insert_user(admin: true)), "/admin/podcasts/duplicates?tab=utilities")

    assert html =~ "Delete alternate feeds"

    assert render_submit(view, "delete_alternate_feeds", %{
             "url" => " https://www.podomatic.com/404.html "
           }) =~ "2 alternate feeds with the URL"

    remaining = from(a in AlternateFeed, select: a.url) |> Repo.all()
    assert remaining == ["https://www.podomatic.com/404.html?x=1"]

    assert render_submit(view, "delete_alternate_feeds", %{"url" => " "}) =~ "Please enter a URL"
  end

  # Manticore isn't reachable in tests, so the repair finds nothing; this only
  # checks that it runs in the background and reports back
  test "repairs the search index in the background", %{conn: conn} do
    {:ok, view, _html} =
      live(as(conn, insert_user(admin: true)), "/admin/podcasts/duplicates?tab=utilities")

    ExUnit.CaptureLog.capture_log(fn ->
      assert render_click(view, "repair_search_index", %{}) =~ "Repairing the search index"
      assert eventually(fn -> render(view) =~ "Search index repaired: 0 deleted podcasts" end)
    end)
  end

  test "fetches the current title of a shared feed on demand", %{conn: conn} do
    Application.put_env(:pan, :ssrf_guard_allowed_hosts, ["localhost"])
    on_exit(fn -> Application.delete_env(:pan, :ssrf_guard_allowed_hosts) end)
    {:ok, _} = TestServer.start()

    TestServer.add("/sixers.xml",
      via: :get,
      to:
        &Plug.Conn.resp(
          &1,
          200,
          ~s(<?xml version="1.0"?><rss version="2.0"><channel><title>Sixers Talk</title></channel></rss>)
        )
    )

    url = TestServer.url("/sixers.xml")
    insert_podcast("Holding Court", url)
    insert_podcast("Sixers Talk (old import)", url)

    {:ok, view, _html} =
      live(as(conn, insert_user(admin: true)), "/admin/podcasts/duplicates?tab=same_feed_url")

    render_async(view)
    key = String.replace(url, ~r/^https?:\/\//, "")

    assert render_click(view, "fetch_feed_title", %{"key" => key, "url" => url}) =~
             "Fetching feed title"

    assert eventually(fn -> render(view) =~ "Feed title: <strong>Sixers Talk</strong>" end)
  end

  test "is for admins only", %{conn: conn} do
    assert {:error, {:redirect, _}} =
             live(as(conn, insert_user(admin: false)), "/admin/podcasts/duplicates")
  end
end
