defmodule Pan.SessionController do
  use Pan.Web, :controller

  def new(conn, _) do
    render conn, "new.html"
  end

  def create(conn, %{"session" =>  %{"username" => user, "password" => pass}}) do
    case Pan.Auth.login_by_username_and_pass(conn, user, pass, repo: Repo) do
      {:ok, conn} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> redirect(to: podcast_frontend_path(conn, :index))
      {:error, _reason, conn} ->
        conn
        |> put_flash(:error, "Invalid username/passwerd combination!")
        |> render("new.html")
    end
  end

  def delete(conn, _) do
    conn
    |> Pan.Auth.logout()
    |> redirect(to: podcast_frontend_path(conn, :index))
  end
end
