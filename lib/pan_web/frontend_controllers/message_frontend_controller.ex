defmodule PanWeb.MessageFrontendController do
  use Pan.Web, :controller
  alias PanWeb.Message

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end

  def delete(conn, %{"id" => id}, user) do
    Repo.one(from(r in Message, where: r.id == ^id and r.creator_id == ^user.id))
    |> Repo.delete!()

    conn
    |> put_flash(:info, "Message deleted successfully.")
    |> redirect(to: user_frontend_path(conn, :my_data))
  end

  def delete_all(conn, _, user) do
    Repo.delete_all(from(r in Message, where: r.creator_id == ^user.id))

    conn
    |> put_flash(:info, "Deleted all your messages successfully.")
    |> redirect(to: user_frontend_path(conn, :my_data))
  end
end
