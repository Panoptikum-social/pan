defmodule Pan.SessionController do
  use Pan.Web, :controller

  def new(conn, _) do
    render conn, "new.html"
  end

  def create(conn, %{"session" =>  %{"username" => user, "password" => pass}}) do
    case Pan.Auth.login_by_username_and_pass(conn, user, pass) do
      {:ok, conn} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> redirect(to: category_frontend_path(conn, :index))
      {:error, _reason, conn} ->
        conn
        |> put_flash(:error, "Invalid username/password combination!")
        |> render("new.html")
    end
  end


  def login_via_token(conn, %{"token" => token}) do
    case Pan.Auth.login_by_token(conn, token) do
      {:ok, conn} ->
        conn
        |> put_flash(:info, "Welcome back, please set your new password!")
        |> redirect(to: user_frontend_path(conn, :edit))
      {:error, :expired} ->
        conn
        |> put_flash(:error, "The token has expired already!")
        |> render("new.html")
      {:error, _reason, conn} ->
        conn
        |> put_flash(:error, "Invalid token!")
        |> render("new.html")
    end
  end


  def delete(conn, _) do
    conn
    |> Pan.Auth.logout()
    |> redirect(to: podcast_frontend_path(conn, :index))
  end
end