defmodule PanWeb.FollowFrontendController do
  use Pan.Web, :controller
  alias PanWeb.Follow


  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end


  def unfollow_all_podcasts(conn, _, user) do
    Repo.delete_all(from f in Follow, where: f.follower_id == ^user.id and not is_nil(f.podcast_id))

    conn
    |> put_flash(:info, "Unfollowed successfully.")
    |> redirect(to: user_frontend_path(conn, :my_data))
  end
end