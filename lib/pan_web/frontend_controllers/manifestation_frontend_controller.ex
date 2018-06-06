defmodule PanWeb.ManifestationFrontendController do
  use Pan.Web, :controller
  alias PanWeb.{Manifestation, Persona}


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


  def delete_all(conn, _, user) do
    Repo.delete_all(from r in Manifestation, where: r.user_id == ^user.id)

    from(r in Persona, where: r.user_id == ^user.id,
                       update: [set: [user_id: nil, email: nil]])
    |> Repo.update_all([])

    conn
    |> put_flash(:info, "All manifestation deleted successfully.")
    |> redirect(to: user_frontend_path(conn, :my_data))
  end
end