defmodule PanWeb.SessionController do
  use PanWeb, :controller

  def create(conn, %{"session" => %{"username" => user, "password" => given_pass}}) do
    case PanWeb.Auth.login_by_username_and_pass(conn, user, given_pass) do
      {:ok, conn} ->
        current_user = conn.assigns.current_user

        case current_user.email_confirmed do
          true ->
            conn
            |> put_flash(:info, "Welcome back!")

          _ ->
            Phoenix.Token.sign(PanWeb.Endpoint, "user", current_user.id)
            |> Pan.Email.email_confirmation_link_html_email(current_user.email)
            |> Pan.Mailer.deliver()

            conn
            |> Phoenix.Controller.put_flash(
              :info,
              "Your email address has not been confirmed yet. Please click on " <>
                "the confirmation link in the email we sent to you right now!"
            )
        end

        if get_session(conn, :desired_url) do
          redirect(conn, to: get_session(conn, :desired_url))
        else
          redirect(conn, to: user_frontend_path(conn, :my_profile))
        end

      {:error, _reason, conn} ->
        conn
        |> put_flash(:error, "Invalid username/password combination!")
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
        |> render("new.html")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Invalid token!")
        |> render("new.html")
    end
  end

  def login_from_signup(conn, %{"token" => token}) do
    case PanWeb.Auth.login_by_token(conn, token) do
      {:ok, conn} ->
        conn
        |> put_flash(:info, "You are now logged in.")
        |> redirect(to: page_frontend_path(conn, :index))

      {:error, :expired} ->
        conn
        |> put_flash(:error, "The token has expired already!")
        |> render("new.html")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Invalid token!")
        |> render("new.html")
    end
  end

  def delete(conn, _) do
    conn
    |> PanWeb.Auth.logout()
    |> redirect(to: "/")
  end

  def confirm_email(conn, %{"token" => token}) do
    case PanWeb.Auth.login_by_token(conn, token) do
      {:ok, conn} ->
        Ecto.Changeset.change(conn.assigns.current_user, email_confirmed: true)
        |> Repo.update()

        conn
        |> put_flash(:info, "Thank you for confirming your email address!")

        render(conn, "email_confirmed.html")

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
