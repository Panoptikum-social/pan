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
    end
  end
end
