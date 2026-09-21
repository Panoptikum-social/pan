defmodule PanWeb.SessionControllerTest do
  use PanWeb.ConnCase

  import Swoosh.TestAssertions

  alias Pan.Repo
  alias PanWeb.User

  defp insert_user(attrs) do
    n = System.unique_integer([:positive])

    %User{
      name: "Test User",
      username: "test_user_#{n}",
      email: "test_user_#{n}@example.com",
      password_hash: Bcrypt.hash_pwd_salt("secret123")
    }
    |> struct(attrs)
    |> Repo.insert!()
  end

  defp login(conn, user) do
    post(conn, "/sessions", %{
      "session" => %{"username" => user.username, "password" => "secret123"}
    })
  end

  describe "password login" do
    test "logs a verified user in", %{conn: conn} do
      user = insert_user(email_verified: true)
      conn = login(conn, user)

      assert redirected_to(conn)
      assert get_session(conn, :user_id) == user.id
    end

    test "records the login time and lifts a deletion mark", %{conn: conn} do
      marked_at = ~N[2026-01-01 00:00:00]
      user = insert_user(email_verified: true, marked_for_deletion_at: marked_at)

      login(conn, user)

      user = Repo.get!(User, user.id)
      assert user.last_login_at
      assert is_nil(user.marked_for_deletion_at)
    end

    test "a blocked login records nothing", %{conn: conn} do
      user = insert_user(email_verified: false)

      login(conn, user)

      refute Repo.get!(User, user.id).last_login_at
    end

    test "blocks an unverified user and offers a new verification mail", %{conn: conn} do
      user = insert_user(email_verified: false)
      conn = login(conn, user)

      assert html_response(conn, 200) =~ "Send verification email again"
      refute get_session(conn, :user_id)
      assert_no_email_sent()
    end

    test "does not reveal an unverified account for a wrong password", %{conn: conn} do
      user = insert_user(email_verified: false)

      conn =
        post(conn, "/sessions", %{"session" => %{"username" => user.username, "password" => "x"}})

      assert redirected_to(conn)
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Invalid username/password"
    end
  end

  describe "resend verification" do
    test "sends a new verification mail to an unverified user", %{conn: conn} do
      user = insert_user(email_verified: false)
      token = Phoenix.Token.sign(PanWeb.Endpoint, "resend verification", user.id)

      conn = post(conn, "/sessions/resend_verification", %{"token" => token})

      assert redirected_to(conn) == "/sessions/new"
      assert_email_sent(to: user.email)
    end

    test "sends nothing to an already verified user", %{conn: conn} do
      user = insert_user(email_verified: true)
      token = Phoenix.Token.sign(PanWeb.Endpoint, "resend verification", user.id)

      post(conn, "/sessions/resend_verification", %{"token" => token})

      assert_no_email_sent()
    end

    test "rejects an invalid token", %{conn: conn} do
      conn = post(conn, "/sessions/resend_verification", %{"token" => "nonsense"})

      assert redirected_to(conn) == "/sessions/new"
      assert_no_email_sent()
    end
  end

  describe "email links" do
    test "the verification link verifies the address", %{conn: conn} do
      user = insert_user(email_verified: false)
      token = Phoenix.Token.sign(PanWeb.Endpoint, "user", user.id)

      conn = get(conn, "/sessions/verify_email", %{"token" => token})

      assert html_response(conn, 200) =~ "verifying your email address"
      assert Repo.get!(User, user.id).email_verified
    end

    test "the login link logs in and verifies the address", %{conn: conn} do
      user = insert_user(email_verified: false)
      token = Phoenix.Token.sign(PanWeb.Endpoint, "user", user.id)

      conn = get(conn, "/sessions/login_via_token", %{"token" => token})

      assert get_session(conn, :user_id) == user.id
      assert Repo.get!(User, user.id).email_verified
      assert Repo.get!(User, user.id).last_login_at
    end
  end

  describe "retention notice link" do
    test "logs in, verifies, records the login and lifts the deletion mark", %{conn: conn} do
      user =
        insert_user(
          email_verified: false,
          marked_for_deletion_at: ~N[2026-08-01 00:00:00]
        )

      token = PanWeb.Auth.sign_token(:retention_notice, user.id)
      conn = get(conn, "/sessions/login_via_notice", %{"token" => token})

      assert get_session(conn, :user_id) == user.id
      user = Repo.get!(User, user.id)
      assert user.email_verified
      assert user.last_login_at
      assert is_nil(user.marked_for_deletion_at)
    end

    test "is valid for 30 days but not longer", %{conn: conn} do
      user = insert_user(email_verified: true)
      day = 60 * 60 * 24

      fresh = signed_token(user, 29 * day)
      assert get_session(get(conn, "/sessions/login_via_notice", %{"token" => fresh}), :user_id)

      stale = signed_token(user, 31 * day)
      conn = get(conn, "/sessions/login_via_notice", %{"token" => stale})
      refute get_session(conn, :user_id)
      assert redirected_to(conn) == "/sessions/new"
    end

    test "the two kinds of login link do not work for each other", %{conn: conn} do
      user = insert_user(email_verified: true)

      notice = PanWeb.Auth.sign_token(:retention_notice, user.id)
      refute get_session(get(conn, "/sessions/login_via_token", %{"token" => notice}), :user_id)

      link = Phoenix.Token.sign(PanWeb.Endpoint, "user", user.id)
      refute get_session(get(conn, "/sessions/login_via_notice", %{"token" => link}), :user_id)
    end
  end

  defp signed_token(user, age_in_seconds) do
    Phoenix.Token.sign(PanWeb.Endpoint, "retention notice", user.id,
      signed_at: System.system_time(:second) - age_in_seconds
    )
  end
end
