defmodule Pan.OPMLController do
  use Pan.Web, :controller

  alias Pan.OPML

  def index(conn, _params) do
    opmls = Repo.all(OPML)
    render(conn, "index.html", opmls: opmls)
  end


  def new(conn, _params) do
    changeset = OPML.changeset(%OPML{})
    render(conn, "new.html", changeset: changeset)
  end


  def create(conn, %{"opml" => opml_params}) do
    user = conn.assigns.current_user
    if upload = opml_params["file"] do
      File.mkdir_p("uploads/opml/#{user.id}")
      destination_path = "uploads/opml/#{user.id}/#{upload.filename}"
      File.cp(upload.path, destination_path)
    end

    changeset = OPML.changeset(%OPML{content_type: upload.content_type,
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
    opml = Repo.get!(OPML, id)
    render(conn, "show.html", opml: opml)
  end


  def edit(conn, %{"id" => id}) do
    opml = Repo.get!(OPML, id)
    changeset = OPML.changeset(opml)
    render(conn, "edit.html", opml: opml, changeset: changeset)
  end


  def update(conn, %{"id" => id, "opml" => opml_params}) do
    opml = Repo.get!(OPML, id)
    changeset = OPML.changeset(opml, opml_params)

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
    opml = Repo.get!(OPML, id)

    File.rm(opml.path)
    Repo.delete!(opml)

    conn
    |> put_flash(:info, "Opml deleted successfully.")
    |> redirect(to: opml_path(conn, :index))
  end
end
