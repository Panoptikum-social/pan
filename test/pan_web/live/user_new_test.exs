defmodule PanWeb.Live.UserNewTest do
  use PanWeb.ConnCase

  import Phoenix.LiveViewTest

  @incomplete "The form is not filled out fully."

  test "the empty sign-up form shows no error", %{conn: conn} do
    {:ok, view, html} = live(conn, "/users/new")
    refute html =~ @incomplete
    refute render(view) =~ @incomplete
  end

  test "typing doesn't show the error before a submit", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/users/new")

    html =
      view
      |> form("form", user: %{name: "New User"})
      |> render_change()

    refute html =~ @incomplete
  end

  test "a failed submit shows the error", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/users/new")

    html =
      view
      |> form("form",
        user: %{
          name: "New User",
          username: "newuser",
          email: "new-user@example.com",
          password: "secret-password",
          password_confirmation: "secret-password",
          bot_check: "41"
        }
      )
      |> render_submit()

    assert html =~ @incomplete
  end
end
