defmodule PanWeb.Live.PadTest do
  use PanWeb.ConnCase

  import Phoenix.LiveViewTest
  import PanWeb.Router.Helpers

  alias Pan.Repo
  alias PanWeb.{Category, Community, Follow, Moderation, Pad, PadServer, PadSnapshot, User}

  defp insert_user do
    n = System.unique_integer([:positive])

    Repo.insert!(%User{
      name: "Test",
      username: "padlive_#{n}",
      email: "padlive_#{n}@example.com",
      moderator: true
    })
  end

  defp insert_community do
    category = Repo.insert!(%Category{title: "Pad live category #{System.unique_integer()}"})
    Repo.insert!(%Community{title: "Pad live community", category_id: category.id})
  end

  defp follow(user, community),
    do: Repo.insert!(%Follow{follower_id: user.id, community_id: community.id})

  defp moderate(user, community),
    do: Repo.insert!(%Moderation{user_id: user.id, community_id: community.id})

  defp logged_in(conn, user), do: init_test_session(conn, %{"user_id" => user.id})

  setup do
    community = insert_community()
    {:ok, pad} = Pad.create(community.id, %{"title" => "Meeting notes"})
    pad = pad |> Ecto.Changeset.change(markdown: "Some **secret** text") |> Repo.update!()
    %{community: community, pad: pad}
  end

  describe "community page" do
    test "visitors and non-followers don't see the pads", %{conn: conn, community: community} do
      path = community_frontend_path(@endpoint, :show, community)

      for conn <- [conn, logged_in(conn, insert_user())] do
        {:ok, _view, html} = live(conn, path)
        refute html =~ "Meeting notes"
        refute html =~ "new-pad-form"
      end
    end

    test "a moderator who doesn't follow sees no pads", %{conn: conn, community: community} do
      user = insert_user()
      moderate(user, community)

      {:ok, _view, html} =
        live(logged_in(conn, user), community_frontend_path(@endpoint, :show, community))

      refute html =~ "Meeting notes"
    end

    test "followers see the pads, without the form", %{conn: conn, community: community} do
      user = insert_user()
      follow(user, community)

      {:ok, _view, html} =
        live(logged_in(conn, user), community_frontend_path(@endpoint, :show, community))

      assert html =~ "Meeting notes"
      refute html =~ "new-pad-form"
    end

    test "the pads appear right after following", %{conn: conn, community: community} do
      {:ok, view, html} =
        live(logged_in(conn, insert_user()), community_frontend_path(@endpoint, :show, community))

      refute html =~ "Meeting notes"
      assert view |> element("button", "Follow") |> render_click()
      assert render(view) =~ "Meeting notes"
    end

    test "a following moderator creates a pad and lands on it", %{
      conn: conn,
      community: community
    } do
      user = insert_user()
      follow(user, community)
      moderate(user, community)

      {:ok, view, _html} =
        live(logged_in(conn, user), community_frontend_path(@endpoint, :show, community))

      assert {:error, {:live_redirect, %{to: to}}} =
               view |> form("#new-pad-form", pad: %{title: "Ideas für 2027"}) |> render_submit()

      assert to == pad_frontend_path(@endpoint, :show, community.id, "ideas-fuer-2027")
      assert Pad.get_by_slug(community.id, "ideas-fuer-2027")
    end

    test "a clashing title shows the error", %{conn: conn, community: community} do
      user = insert_user()
      follow(user, community)
      moderate(user, community)

      {:ok, view, _html} =
        live(logged_in(conn, user), community_frontend_path(@endpoint, :show, community))

      assert view |> form("#new-pad-form", pad: %{title: "meeting notes"}) |> render_submit() =~
               "already exists"
    end
  end

  describe "pad page" do
    test "visitors, non-followers and non-following moderators get not found",
         %{conn: conn, community: community, pad: pad} do
      moderator = insert_user()
      moderate(moderator, community)
      path = pad_frontend_path(@endpoint, :show, community.id, pad.slug)

      for conn <- [conn, logged_in(conn, insert_user()), logged_in(conn, moderator)] do
        {:ok, _view, html} = live(conn, path)
        assert html =~ "could not be found"
        refute html =~ "secret"
      end
    end

    test "followers get the editor, without the manage controls",
         %{conn: conn, community: community, pad: pad} do
      user = insert_user()
      follow(user, community)

      {:ok, view, html} =
        live(logged_in(conn, user), pad_frontend_path(@endpoint, :show, community.id, pad.slug))

      assert html =~ ~s(phx-hook="PadEditor")
      assert has_element?(view, "#pad-editor-#{pad.id}[data-pad-id='#{pad.id}']")
      refute has_element?(view, "#toggle-read-only")
      refute has_element?(view, "#delete-pad")
    end

    test "a following moderator toggles read only, renames and deletes",
         %{conn: conn, community: community, pad: pad} do
      user = insert_user()
      follow(user, community)
      moderate(user, community)

      {:ok, view, _html} =
        live(logged_in(conn, user), pad_frontend_path(@endpoint, :show, community.id, pad.slug))

      view |> element("#toggle-read-only") |> render_click()
      assert Repo.get!(Pad, pad.id).read_only
      assert render(view) =~ "Make editable"

      assert {:error, {:live_redirect, %{to: to}}} =
               view |> form("#rename-pad-form", pad: %{title: "Old notes"}) |> render_submit()

      assert to == pad_frontend_path(@endpoint, :show, community.id, "old-notes")

      {:ok, view, _html} = live(logged_in(conn, user), to)

      assert {:error, {:live_redirect, %{to: to}}} =
               view |> element("#delete-pad") |> render_click()

      assert to == community_frontend_path(@endpoint, :show, community)
      refute Repo.get(Pad, pad.id)
    end

    test "a follower saves, views and restores versions, not while read only",
         %{conn: conn, community: community, pad: pad} do
      user = insert_user()
      follow(user, community)

      {:ok, view, _html} =
        live(logged_in(conn, user), pad_frontend_path(@endpoint, :show, community.id, pad.slug))

      html =
        view
        |> form("#save-version-form", version: %{note: "Before the meeting"})
        |> render_submit()

      assert html =~ "Version saved."
      assert render(view) =~ "Before the meeting"
      assert [%{user_id: user_id, note: "Before the meeting"}] = Repo.all(PadSnapshot)
      assert user_id == user.id

      old = Repo.insert!(%PadSnapshot{pad_id: pad.id, markdown: "An *older* text"})
      send(view.pid, :snapshots_changed)

      assert view |> element("#pad-version-#{old.id} button", "View") |> render_click() =~
               "<em>older</em>"

      assert render(view) =~ "automatic"

      view |> element("#pad-version-#{old.id} button", "Restore") |> render_click()
      server = PadServer.whereis(pad.id)
      text = :sys.get_state(server).doc |> Yex.Doc.get_text(PadServer.text_name())
      assert Yex.Text.to_string(text) == "An *older* text"

      pad |> Pad.read_only_changeset(true) |> Repo.update!()

      assert view |> element("#pad-version-#{old.id} button", "Restore") |> render_click() =~
               "This pad is read only."

      DynamicSupervisor.terminate_child(Pan.PadSupervisor, server)
    end

    test "manage events from a moderator who stopped following are refused",
         %{conn: conn, community: community, pad: pad} do
      user = insert_user()
      follow = follow(user, community)
      moderate(user, community)

      {:ok, view, _html} =
        live(logged_in(conn, user), pad_frontend_path(@endpoint, :show, community.id, pad.slug))

      Repo.delete!(follow)
      assert view |> element("#delete-pad") |> render_click() =~ "Only moderators"
      assert Repo.get(Pad, pad.id)
    end
  end

  test "My Moderations warns about moderated communities that aren't followed",
       %{conn: conn, community: community} do
    user = insert_user()
    moderate(user, community)
    followed = insert_community()
    moderate(user, followed)
    follow(user, followed)

    html = conn |> logged_in(user) |> get("/moderator/my_moderations") |> html_response(200)

    assert html =~ "follow every community you moderate."
    assert html =~ community_frontend_path(@endpoint, :show, community)
    refute html =~ community_frontend_path(@endpoint, :show, followed)
  end
end
