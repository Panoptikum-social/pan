defmodule PanWeb.ManifestationFrontendController do
  use Pan.Web, :controller
  alias PanWeb.Manifestation


  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end


  def delete(conn, %{"id" => id}, user) do
    Repo.one(from r in Manifestation, where: r.persona_id == ^id and r.user_id == ^user.id)
    |> Repo.delete!()

    conn
    |> put_flash(:info, "Manifestation deleted successfully.")
    |> redirect(to: user_frontend_path(conn, :my_data))
  end
end