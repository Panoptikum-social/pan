defmodule PanWeb.Live.Admin.UserRetentionTest do
  use PanWeb.ConnCase

  import Phoenix.LiveViewTest
  import Swoosh.TestAssertions

  alias Pan.Repo
  alias PanWeb.User

  defp insert_user(attrs) do
    n = System.unique_integer([:positive])

    %User{name: "Test", username: "retention_#{n}", email: "retention_#{n}@example.com"}
    |> struct(attrs)
    |> Repo.insert!()
  end

  defp days_ago(days), do: NaiveDateTime.add(Pan.Parser.MyDateTime.now(), -days, :day)

  defp wait_for(view, text, tries \\ 50) do
    cond do
      render(view) =~ text ->
        true

      tries == 0 ->
        false

      true ->
        Process.sleep(20)
        wait_for(view, text, tries - 1)
    end
  end

  defp admin_conn(conn) do
    admin = insert_user(admin: true, email_verified: true)
    init_test_session(conn, %{"user_id" => admin.id, "admin" => true})
  end

  test "is not available to anonymous or non-admin users", %{conn: conn} do
    assert redirected_to(get(conn, "/admin/users/retention")) =~ "/sessions/new"

    user = insert_user(email_verified: true)
    conn = init_test_session(conn, %{"user_id" => user.id, "admin" => false})
    assert redirected_to(get(conn, "/admin/users/retention")) =~ "/sessions/new"
  end

  test "lists users, marks the selected and removes the mark again", %{conn: conn} do
    user = insert_user(email_verified: false)
    {:ok, view, html} = live(admin_conn(conn), "/admin/users/retention")

    assert html =~ user.username

    render_click(view, "toggle", %{"id" => to_string(user.id)})
    assert render_click(view, "mark") =~ "Marked 1 users for deletion."
    assert Repo.get!(User, user.id).marked_for_deletion_at

    render_click(view, "filter", %{"filter" => "marked"})
    render_click(view, "toggle", %{"id" => to_string(user.id)})
    assert render_click(view, "unmark") =~ "Removed the deletion mark from 1 users."
    refute Repo.get!(User, user.id).marked_for_deletion_at
  end

  test "deletes only users past the grace period, even if more are selected", %{conn: conn} do
    long_marked = insert_user(marked_for_deletion_at: days_ago(40))
    just_marked = insert_user(marked_for_deletion_at: days_ago(2))
    {:ok, view, _html} = live(admin_conn(conn), "/admin/users/retention")

    render_click(view, "filter", %{"filter" => "marked"})
    render_click(view, "select_all")

    assert render_click(view, "delete") =~ "Deleted 1 users."

    refute Repo.get(User, long_marked.id)
    assert Repo.get(User, just_marked.id)
  end

  test "checked filters apply together and unchecking widens the list again", %{conn: conn} do
    plain = insert_user(email_verified: true)
    marked = insert_user(email_verified: true, marked_for_deletion_at: days_ago(3))
    {:ok, view, html} = live(admin_conn(conn), "/admin/users/retention")

    assert html =~ plain.username
    assert html =~ marked.username

    html = render_click(view, "filter", %{"filter" => "marked"})
    refute html =~ plain.username
    assert html =~ marked.username

    html = render_click(view, "filter", %{"filter" => "unverified"})
    refute html =~ marked.username

    render_click(view, "filter", %{"filter" => "unverified"})
    html = render_click(view, "filter", %{"filter" => "marked"})
    assert html =~ plain.username
  end

  test "sends notices to the selected users and marks them", %{conn: conn} do
    Application.put_env(:swoosh, :shared_test_process, self())
    on_exit(fn -> Application.delete_env(:swoosh, :shared_test_process) end)

    user = insert_user(email_verified: false)
    {:ok, view, _html} = live(admin_conn(conn), "/admin/users/retention")

    render_click(view, "toggle", %{"id" => to_string(user.id)})
    assert render_click(view, "send_notices") =~ "Sending 1 notices"

    # the mails are sent from a background task, wait for its report
    assert wait_for(view, "Sent 1 notices")
    assert_email_sent(to: {"", user.email})
    assert Repo.get!(User, user.id).marked_for_deletion_at
  end

  test "the search box narrows the list to matching usernames or emails", %{conn: conn} do
    wanted = insert_user(username: "searchable_person", email: "wanted@example.com")
    by_mail = insert_user(username: "someone_else", email: "hello@searchable.example.org")
    other = insert_user(username: "unrelated_person", email: "other@example.com")
    {:ok, view, html} = live(admin_conn(conn), "/admin/users/retention")

    assert html =~ other.username

    html = view |> element("#retention-search") |> render_change(%{"search" => "searchable"})
    assert html =~ wanted.username
    assert html =~ by_mail.username
    refute html =~ other.username

    html = view |> element("#retention-search") |> render_change(%{"search" => ""})
    assert html =~ other.username
  end
end
