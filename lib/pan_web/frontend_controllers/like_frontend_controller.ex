defmodule PanWeb.LikeFrontendController do
  use Pan.Web, :controller
  alias PanWeb.Like


  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end


  def unlike_all_podcasts(conn, _, user) do
    Repo.delete_all(from l in Like, where: l.enjoyer_id == ^user.id and not is_nil(l.podcast_id))

    conn
    |> put_flash(:info, "Unliked all podcasts successfully.")
    |> redirect(to: user_frontend_path(conn, :my_data))
  end
end