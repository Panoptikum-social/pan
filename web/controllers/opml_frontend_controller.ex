defmodule Pan.OpmlFrontendController do
  use Pan.Web, :controller

  alias Pan.Opml

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end

  def index(conn, _params, user) do
    opmls = Repo.all(from o in Opml, where: o.user_id == ^user.id)
    render(conn, "index.html", opmls: opmls)
  end


  def new(conn, _params, _user) do
    changeset = Opml.changeset(%Opml{})
    render(conn, "new.html", changeset: changeset)
  end


  def create(conn, %{"opml" => opml_params}, user) do
    destination_path =
      if upload = opml_params["file"] do
        File.mkdir_p("/var/phoenix/pan-uploads/opml/#{user.id}")
        path = "/var/phoenix/pan-uploads/opml/#{user.id}/#{upload.filename}"
        File.cp(upload.path, path)
        path
      else
        ""
      end

    changeset = Opml.changeset(%Opml{content_type: upload.content_type,
                                     filename: upload.filename,
                                     path: destination_path,
                                     user_id: user.id})

    case Repo.insert(changeset) do
      {:ok, _opml} ->
        conn
        |> put_flash(:info, "Opml created successfully.")
        |> redirect(to: opml_frontend_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end


  def delete(conn, %{"id" => id}, user) do
    opml = Repo.one(from o in Opml, where: o.id == ^id and o.user_id == ^user.id)

    File.rm(opml.path)
    Repo.delete!(opml)

    conn
    |> put_flash(:info, "Opml deleted successfully.")
    |> redirect(to: opml_frontend_path(conn, :index))
  end


  def import(conn, %{"id" => id}, user) do
    opml = Repo.one(from o in Opml, where: o.id == ^id and o.user_id == ^user.id)

    Pan.OpmlParser.Opml.parse(opml.path, user.id)
    conn
    |> put_flash(:info, "Opml imported successfully.")
    |> redirect(to: opml_frontend_path(conn, :index))
  end
end
