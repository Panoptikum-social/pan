defmodule Pan.UserController do
  use Pan.Web, :controller

  def index(conn, _params) do
    users = Repo.all(Pan.User)
    render conn, "index.html", users: users
  end

  def show(conn, %{"id" => id}) do
    user = Repo.get(Pan.User, id)
    render conn, "show.html", user: user
  end
end
