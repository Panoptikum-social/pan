defmodule Pan.UserFrontendController do
  use Pan.Web, :controller
  alias Pan.Message

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end


  def profile(conn, _params, user) do
    user_id = Integer.to_string(user.id)
    messages = Repo.all(from m in Message, order_by: [desc: :inserted_at],
                                           where: m.topic == "mailboxes" and m.subtopic == ^user_id,
                                           preload: [:creator])
    render conn, "profile.html", user: user, messages: messages
  end


  def index(conn, _params, _user) do
    users = Repo.all(from u in Pan.User, order_by: :name,
                                         where: u.podcaster == true)
    render conn, "index.html", users: users
  end


  def show(conn, %{"id" => id}, _user) do
    user = Repo.one(from u in Pan.User, where: u.id == ^id and u.podcaster == true)
           |> Repo.preload(:owned_podcasts)
    render conn, "show.html", user: user
  end
end