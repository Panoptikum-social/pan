defmodule PanWeb.InvoiceFrontendController do
  use Pan.Web, :controller
  alias PanWeb.Invoice


  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end


  def download(conn, %{"id" => id}, user) do
    case Repo.one(from i in Invoice, where: i.id == ^id and i.user_id == ^user.id) do
      nil ->
        conn
        |> put_flash(:error, "This is not a valid invoice for you")
        |> redirect(to: user_frontend_path(conn, :my_profile))
        |> halt()

      invoice ->
        conn
        |> put_resp_content_type("application/octet-stream", "utf-8")
        |> put_resp_header("content-disposition", ~s[attachment; filename="#{invoice.filename}"])
        |> send_file(200, invoice.path)
    end
  end
end