defmodule PanWeb.Live.Admin.PodcastDuplicatesTest do
  use PanWeb.ConnCase

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

    {:ok, view, _html} = live(as(conn, insert_user(admin: true)), "/admin/podcasts/duplicates")
    html = render_async(view)

    for title <- ["Double import again", "deportes", "Stale copy", "Holding Court"] do
      assert html =~ title
    end

    assert html =~ "0 % of its episodes known"
  end

  test "is for admins only", %{conn: conn} do
    assert {:error, {:redirect, _}} =
             live(as(conn, insert_user(admin: false)), "/admin/podcasts/duplicates")
  end
end
