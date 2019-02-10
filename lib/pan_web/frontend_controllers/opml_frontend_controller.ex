defmodule PanWeb.OpmlFrontendController do
  use Pan.Web, :controller
  alias PanWeb.Opml

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


  def create(conn, _, _user) do
    conn
    |> put_flash(:info, "No file selected!")
    |> redirect(to: opml_frontend_path(conn, :new))
  end


  def delete(conn, %{"id" => id}, user) do
    opml = Repo.one(from o in Opml, where: o.id == ^id and o.user_id == ^user.id)

    File.rm(opml.path)
    Repo.delete!(opml)

    conn
    |> put_flash(:info, "OPML deleted successfully.")
    |> redirect(to: opml_frontend_path(conn, :index))
  end


  def download(conn, %{"id" => id}, user) do
    case Repo.one(from o in Opml, where: o.id == ^id and o.user_id == ^user.id) do
      nil ->
        conn
        |> put_flash(:error, "This is not a valid OPML for you")
        |> redirect(to: opml_frontend_path(conn, :index))
        |> halt()

      opml ->
        conn
        |> put_resp_content_type("application/octet-stream", "utf-8")
        |> put_resp_header("content-disposition", ~s[attachment; filename="#{opml.filename}"])
        |> send_file(200, opml.path)
    end
  end


  def import(conn, %{"id" => id}, user) do
    opml = Repo.one(from o in Opml, where: o.id == ^id and o.user_id == ^user.id)

    Pan.OpmlParser.Opml.parse(opml.path, user.id)
    conn
    |> put_flash(:info, Phoenix.HTML.raw(
                          "<span class='h3'>Thank you!</span><br/> The OPML was imported into the" <>
                          " feed backlog successfully.<br/> We will parse the feeds as soon as" <>
                          " possible and assign you as listener to the corresponding podcasts."
                        )
       )
    |> redirect(to: opml_frontend_path(conn, :index))
  end
end
