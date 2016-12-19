defmodule Pan.OpmlController do
  use Pan.Web, :controller

  alias Pan.Opml

  def index(conn, _params) do
    opmls = Repo.all(Opml, order: [desc: :inserted_at])
            |> Repo.preload(:user)
    render(conn, "index.html", opmls: opmls)
  end


  def new(conn, _params) do
    changeset = Opml.changeset(%Opml{})
    render(conn, "new.html", changeset: changeset)
  end


  def create(conn, %{"opml" => opml_params}) do
    user = conn.assigns.current_user
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
        |> redirect(to: opml_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end


  def show(conn, %{"id" => id}) do
    opml = Repo.get!(Opml, id)
    render(conn, "show.html", opml: opml)
  end


  def edit(conn, %{"id" => id}) do
    opml = Repo.get!(Opml, id)
    changeset = Opml.changeset(opml)
    render(conn, "edit.html", opml: opml, changeset: changeset)
  end


  def update(conn, %{"id" => id, "opml" => opml_params}) do
    opml = Repo.get!(Opml, id)
    changeset = Opml.changeset(opml, opml_params)

    case Repo.update(changeset) do
      {:ok, opml} ->
        conn
        |> put_flash(:info, "Opml updated successfully.")
        |> redirect(to: opml_path(conn, :show, opml))
      {:error, changeset} ->
        render(conn, "edit.html", opml: opml, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    opml = Repo.get!(Opml, id)

    File.rm(opml.path)
    Repo.delete!(opml)

    conn
    |> put_flash(:info, "Opml deleted successfully.")
    |> redirect(to: opml_path(conn, :index))
  end


  def import(conn, %{"id" => id}) do
    opml = Repo.get!(Opml, id)

    Pan.OpmlParser.Opml.parse(opml.path, opml.user_id)
    conn
    |> put_flash(:info, "Opml imported successfully.")
    |> redirect(to: opml_frontend_path(conn, :index))
  end
end
