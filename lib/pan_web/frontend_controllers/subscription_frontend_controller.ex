defmodule PanWeb.SubscriptionFrontendController do
  use Pan.Web, :controller
  alias PanWeb.Subscription

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end


  def delete_all(conn, _, user) do
    Repo.delete_all(from s in Subscription, where: s.user_id == ^user.id)

    conn
    |> put_flash(:info, "Deleted all your subscriptions successfully.")
    |> redirect(to: user_frontend_path(conn, :my_data))
  end
end