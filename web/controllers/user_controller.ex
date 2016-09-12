defmodule Pan.UserController do
  use Pan.Web :controller

  def index(conn, _params) do
    users = Repo.all(Pan.User)
    render conn, "index.html", users: users
  end
end
