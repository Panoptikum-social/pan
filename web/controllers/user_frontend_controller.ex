defmodule Pan.UserFrontendController do
  use Pan.Web, :controller
  alias Pan.Message

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end


  def show(conn, _params, user) do
    user_id = Integer.to_string(user.id)
    messages = Repo.all(from m in Message, order_by: [desc: :inserted_at],
                                           where: m.topic == "mailboxes" and m.subtopic == ^user_id,
                                           preload: [:creator])
    render conn, "show.html", user: user, messages: messages
  end
end