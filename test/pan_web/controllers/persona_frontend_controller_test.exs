defmodule PanWeb.PersonaFrontendControllerTest do
  use PanWeb.ConnCase, async: true

  alias Pan.Repo
  alias PanWeb.{Delegation, Manifestation, Persona, User}

  setup %{conn: conn} do
    n = System.unique_integer([:positive])

    user =
      Repo.insert!(%User{name: "Owner", username: "owner_#{n}", email: "owner_#{n}@example.com"})

    persona = Repo.insert!(%Persona{pid: "a-#{n}", name: "A"})
    target = Repo.insert!(%Persona{pid: "b-#{n}", name: "B"})

    for p <- [persona, target],
        do: Repo.insert!(%Manifestation{user_id: user.id, persona_id: p.id})

    %{
      conn: init_test_session(conn, %{"user_id" => user.id}),
      persona: persona,
      target: target
    }
  end

  test "delegation is toggled by POST, no longer by GET (#590)", %{
    conn: conn,
    persona: persona,
    target: target
  } do
    path = "/pan/personas/#{persona.id}/toggle_delegation?delegate_id=#{target.id}"

    assert conn |> get(path) |> response(404)

    assert conn |> post(path) |> redirected_to() == "/pan/my_profile"
    assert Repo.get_by(Delegation, persona_id: persona.id, delegate_id: target.id)

    post(conn, path)
    refute Repo.get_by(Delegation, persona_id: persona.id, delegate_id: target.id)
  end

  test "redirect and cancel_redirect are POST (#590)", %{
    conn: conn,
    persona: persona,
    target: target
  } do
    post(conn, "/pan/personas/#{persona.id}/redirect?target_id=#{target.id}")
    assert Repo.get!(Persona, persona.id).redirect_id == target.id

    post(conn, "/pan/personas/#{persona.id}/cancel_redirect")
    assert Repo.get!(Persona, persona.id).redirect_id == nil
  end

  test "someone else's persona is refused without a crash", %{conn: conn, target: target} do
    stranger = Repo.insert!(%Persona{pid: "c-#{System.unique_integer()}", name: "C"})

    conn = post(conn, "/pan/personas/#{stranger.id}/redirect?target_id=#{target.id}")

    assert redirected_to(conn) == "/pan/my_profile"
    assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "not allowed"
    assert Repo.get!(Persona, stranger.id).redirect_id == nil
  end

  describe "warning page" do
    test "renders the description as markdown, the fediverse address as text (#707)", %{
      conn: conn
    } do
      persona =
        Repo.insert!(%Persona{
          pid: "w-#{System.unique_integer([:positive])}",
          name: "W",
          uri: "https://example.org",
          long_description: "Some **bold** text",
          fediverse_address: "@someone@example.social"
        })

      html = conn |> get("/pan/personas/#{persona.id}/warning") |> html_response(200)

      assert html =~ "<strong>bold</strong>"
      refute html =~ "**bold**"
      assert html =~ "@someone@example.social"
      refute html =~ ~s|href="@someone@example.social"|
      assert html =~ ~s|href="https://example.org" target="_blank"|
    end

    test "an unknown or non-integer id is a 404 (#714)", %{conn: conn} do
      assert_error_sent(404, fn -> get(conn, "/pan/personas/0/warning") end)
      assert_error_sent(404, fn -> get(conn, "/pan/personas/abc/warning") end)
    end
  end
end
