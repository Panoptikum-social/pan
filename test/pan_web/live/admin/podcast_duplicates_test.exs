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
          {"same_title", "deportes"},
          {"alternate", "Stale copy"}
        ] do
      {:ok, view, _html} = live(conn, "/admin/podcasts/duplicates?tab=#{tab}")
      assert render_async(view) =~ expected
    end
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

  test "is for admins only", %{conn: conn} do
    assert {:error, {:redirect, _}} =
             live(as(conn, insert_user(admin: false)), "/admin/podcasts/duplicates")
  end
end
