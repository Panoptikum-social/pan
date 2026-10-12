defmodule PanWeb.PodcastNamesakeTest do
  use PanWeb.ConnCase

  import Phoenix.LiveViewTest
  alias Pan.Repo
  alias PanWeb.{Feed, Podcast, PodcastMerge, User}

  defp insert_podcast(title, attrs \\ []) do
    n = System.unique_integer([:positive])

    podcast =
      %Podcast{title: title, update_intervall: 10, next_update: ~N[2026-01-01 00:00:00]}
      |> struct(attrs)
      |> Repo.insert!()

    Repo.insert!(%Feed{podcast_id: podcast.id, self_link_url: "https://example.com/#{n}.xml"})
    podcast
  end

  defp as_admin(conn) do
    n = System.unique_integer([:positive])

    admin =
      Repo.insert!(%User{
        name: "Admin",
        username: "ns_#{n}",
        email: "ns_#{n}@example.com",
        admin: true
      })

    init_test_session(conn, %{"user_id" => admin.id, "admin" => true})
  end

  test "only marked podcasts with the same title are namesakes" do
    a = insert_podcast("Deportes", namesake: true)
    b = insert_podcast(" deportes", namesake: true)
    insert_podcast("Deportes")
    insert_podcast("Something else", namesake: true)

    assert Podcast.namesakes(a) == [%{id: b.id, title: " deportes"}]
    assert Podcast.namesakes(insert_podcast("Deportes")) == []
  end

  test "a podcast left alone with its title loses the namesake mark" do
    a = insert_podcast("Embedded", namesake: true)
    b = insert_podcast("Embedded", namesake: true)
    c = insert_podcast("Embedded", namesake: true)

    Repo.delete!(c)
    Podcast.clear_lonely_namesake("Embedded")
    assert Repo.get!(Podcast, a.id).namesake

    assert {:ok, _message} = PodcastMerge.merge(b.id, a.id)
    refute Repo.get!(Podcast, a.id).namesake
  end

  test "marked groups leave the same title tab until another one comes along", %{conn: conn} do
    a = insert_podcast("Interface")
    b = insert_podcast("Interface")
    conn = as_admin(conn)

    {:ok, view, _html} = live(conn, "/admin/podcasts/duplicates?tab=same_title")
    assert render_async(view) =~ "Mark as namesakes"

    render_click(view, "mark_namesakes", %{"ids" => "#{a.id},#{b.id}"})
    refute render_async(view) =~ "Mark as namesakes"

    insert_podcast("Interface")
    {:ok, view, _html} = live(conn, "/admin/podcasts/duplicates?tab=same_title")
    assert render_async(view) =~ "Mark as namesakes"
  end

  test "the podcast page points to its namesakes", %{conn: conn} do
    a = insert_podcast("Upstream", namesake: true)
    b = insert_podcast("Upstream", namesake: true)

    {:ok, _view, html} = live(conn, "/podcasts/#{a.id}")
    assert html =~ "There is another podcast with the same title"
    assert html =~ "/podcasts/#{b.id}"
  end
end
