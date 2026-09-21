defmodule PanWeb.Live.Admin.PodcastOwnersTest do
  use PanWeb.ConnCase

  import Ecto.Query
  import Phoenix.LiveViewTest

  alias Pan.Repo
  alias PanWeb.{Engagement, Journal, Persona, Podcast, User}

  defp insert_user(attrs) do
    n = System.unique_integer([:positive])

    %User{name: "Test", username: "owners_#{n}", email: "owners_#{n}@example.com"}
    |> struct(attrs)
    |> Repo.insert!()
  end

  defp insert_podcast(attrs \\ []) do
    n = System.unique_integer([:positive])

    %Podcast{title: "Owners podcast #{n}", description: "d"}
    |> struct(attrs)
    |> Repo.insert!()
  end

  defp admin_conn(conn) do
    admin = insert_user(admin: true, email_verified: true)
    {init_test_session(conn, %{"user_id" => admin.id, "admin" => true}), admin}
  end

  test "is not available to non-admin users", %{conn: conn} do
    user = insert_user(email_verified: true)
    conn = init_test_session(conn, %{"user_id" => user.id, "admin" => false})
    assert redirected_to(get(conn, "/admin/podcasts/owners")) =~ "/sessions/new"
  end

  test "assigns, reassigns and unassigns a podcast, journaling each change", %{conn: conn} do
    {conn, admin} = admin_conn(conn)
    first = insert_user(email_verified: true)
    second = insert_user(email_verified: true)
    podcast = insert_podcast()

    persona =
      Repo.insert!(%Persona{pid: "owners-#{podcast.id}", name: "O", email: "feed@owner.org"})

    Repo.insert!(%Engagement{podcast_id: podcast.id, persona_id: persona.id, role: "owner"})

    {:ok, view, _html} = live(conn, "/admin/podcasts/owners")

    html = view |> form("#owners-search", %{search: podcast.title}) |> render_change()
    assert html =~ podcast.title
    assert html =~ "feed@owner.org"

    view |> element("form[phx-submit=assign]") |> render_submit(%{user: first.username})
    assert Repo.get!(Podcast, podcast.id).user_id == first.id

    view |> element("form[phx-submit=assign]") |> render_submit(%{user: second.email})
    assert Repo.get!(Podcast, podcast.id).user_id == second.id

    view |> element("button", "Unassign") |> render_click()
    assert Repo.get!(Podcast, podcast.id).user_id == nil

    entries = Repo.all(from(j in Journal, where: like(j.text, ^"podcast #{podcast.id} owner%")))

    assert entries |> Enum.map(& &1.method) |> Enum.sort() ==
             ["assign_owner", "assign_owner", "unassign_owner"]

    assert Enum.all?(entries, &(&1.text =~ "admin #{admin.id}"))
  end

  test "reports an unknown user and changes nothing", %{conn: conn} do
    {conn, _admin} = admin_conn(conn)
    podcast = insert_podcast()

    {:ok, view, _html} = live(conn, "/admin/podcasts/owners")
    view |> form("#owners-search", %{search: podcast.title}) |> render_change()

    assert view |> element("form[phx-submit=assign]") |> render_submit(%{user: "nobody-here"}) =~
             "No user found"

    assert Repo.get!(Podcast, podcast.id).user_id == nil
  end

  test "find_by_identifier accepts id, username and email case-insensitively" do
    user = insert_user([])

    assert User.find_by_identifier(to_string(user.id)).id == user.id
    assert User.find_by_identifier(String.upcase(user.username)).id == user.id
    assert User.find_by_identifier(" " <> String.upcase(user.email) <> " ").id == user.id
    assert User.find_by_identifier("nobody-here") == nil
  end
end
