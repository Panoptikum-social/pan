defmodule PanWeb.SessionController do
  use PanWeb, :controller

  def create(conn, %{"session" => %{"username" => user, "password" => given_pass} = params}) do
    remember_me? = params["remember_me"] == "true"

    case PanWeb.Auth.login_by_username_and_pass(conn, user, given_pass, remember_me?) do
      {:ok, conn} ->
        conn = put_flash(conn, :info, "Welcome back!")

        if get_session(conn, :desired_url) do
          redirect(conn, to: get_session(conn, :desired_url))
        else
          redirect(conn, to: user_frontend_path(conn, :my_profile))
        end

      {:error, {:unverified, user}, conn} ->
        token = Phoenix.Token.sign(PanWeb.Endpoint, "resend verification", user.id)
        render(conn, "unverified.html", token: token)

      {:error, _reason, conn} ->
        conn
        |> put_flash(:error, "Invalid username/password combination!")
        |> redirect(to: session_path(conn, :new))
    end
  end

  def resend_verification(conn, %{"token" => token}) do
    case Phoenix.Token.verify(PanWeb.Endpoint, "resend verification", token, max_age: 60 * 60) do
      {:ok, user_id} ->
        user = Repo.get!(PanWeb.User, user_id)

        unless user.email_verified do
          Phoenix.Token.sign(PanWeb.Endpoint, "user", user.id)
          |> Pan.Email.email_verification_link_html_email(user.email)
          |> Pan.Mailer.deliver()
        end

        conn
        |> put_flash(
          :info,
          "We sent you a new verification email. Please click the link in it, then log in."
        )
        |> redirect(to: session_path(conn, :new))

      {:error, _reason} ->
        conn
        |> put_flash(:error, "That request has expired, please log in again.")
        |> redirect(to: session_path(conn, :new))
    end
  end

  def login_via_token(conn, %{"token" => token}) do
    case PanWeb.Auth.login_by_token(conn, token) do
      {:ok, conn} ->
        conn
        |> put_flash(:info, "Welcome back, please set your new password!")
        |> redirect(to: user_frontend_path(conn, :edit_password))

      {:error, :expired} ->
        conn
        |> put_flash(:error, "The token has expired already!")
        |> redirect(to: session_path(conn, :new))

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Invalid token!")
        |> redirect(to: session_path(conn, :new))
    end
  end

  def delete(conn, _) do
    conn
    |> PanWeb.Auth.logout()
    |> redirect(to: "/")
  end

  def verify_email(conn, %{"token" => token}) do
    case PanWeb.Auth.login_by_token(conn, token) do
      {:ok, conn} ->
        conn
        |> put_flash(:info, "Thank you for verifying your email address!")

        render(conn, "email_verified.html")

      {:error, :expired} ->
        conn
        |> put_flash(:error, "The token has expired already!")
        |> render("error.html")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Invalid token!")
        |> render("error.html")
    end
  end
end
