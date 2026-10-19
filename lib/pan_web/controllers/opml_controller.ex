defmodule PanWeb.OpmlController do
  use PanWeb, :controller
  alias PanWeb.Opml

  def new(conn, _params) do
    changeset = Opml.changeset(%Opml{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"opml" => opml_params}) do
    destination_path =
      if upload = opml_params["file"] do
        File.mkdir_p("/var/phoenix/pan-uploads/opml/#{opml_params["user_id"]}")

        path =
          "/var/phoenix/pan-uploads/opml/#{opml_params["user_id"]}/#{PanWeb.Upload.safe_filename(upload.filename)}"

        File.cp(upload.path, path)
        path
      else
        ""
      end

    changeset =
      if upload do
        Opml.changeset(%Opml{
          content_type: upload.content_type,
          filename: PanWeb.Upload.safe_filename(upload.filename),
          path: destination_path,
          user_id: opml_params["user_id"]
        })
      else
        Opml.changeset(%Opml{
          content_type: nil,
          filename: nil,
          path: destination_path,
          user_id: opml_params["user_id"]
        })
      end

    case Repo.insert(changeset) do
      {:ok, _opml} ->
        conn
        |> put_flash(:info, "OPML created successfully.")
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
        |> put_flash(:info, "OPML updated successfully.")
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
    |> put_flash(:info, "OPML deleted successfully.")
    |> redirect(to: opml_path(conn, :index))
  end

  def import(conn, %{"id" => id}) do
    opml = Repo.get!(Opml, id)

    case Pan.OpmlParser.Opml.parse(opml.path, opml.user_id) do
      {:ok, count} -> put_flash(conn, :info, "OPML imported successfully, #{count} feeds.")
      {:error, message} -> put_flash(conn, :error, "OPML not imported: #{message}")
    end
    |> redirect(to: opml_frontend_path(conn, :index))
  end
end
