defmodule PanWeb.Api.OpmlController do
  use Pan.Web, :controller
  alias PanWeb.Opml
  use JaSerializer
  alias PanWeb.Api.Helpers
  import Pan.Parser.Helpers, only: [mark_if_deleted: 1]

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end

  def index(conn, _params, user) do
    opmls = from(o in Opml, where: o.user_id == ^user.id,
                            preload: :user)
            |> Repo.all()

    render conn, "index.json-api", data: opmls,
                                   opts: [include: "user"]
  end


  def show(conn, %{"id" => id}, user) do
    opml = from(o in Opml, where: o.user_id == ^user.id and
                                  o.id == ^id,
                           limit: 1,
                           preload: :user)
           |> Repo.all()

    if opml != [] do
      render conn, "show.json-api", data: opml,
                                    opts: [include: "user"]
    else
      Helpers.send_404(conn)
    end
  end


  def create(conn, %{"upload" => upload}, user) do
    with %Plug.Upload{} <- upload do

      File.mkdir_p("/var/phoenix/pan-uploads/opml/#{user.id}")
      path = "/var/phoenix/pan-uploads/opml/#{user.id}/#{upload.filename}"
      File.cp(upload.path, path)

      changeset = %Opml{content_type: upload.content_type,
                        filename: upload.filename,
                        path: path,
                        user_id: user.id}
                  |> Opml.changeset()

      case Repo.insert(changeset) do
        {:ok, opml} ->
          opml = Repo.preload(opml, :user)

          conn
          |> render("show.json-api", data: opml,
                                     opts: [include: "user"])
        {:error, changeset} ->
          conn
          |> put_status(422)
          |> render(:errors, data: changeset)
      end
    else
      nil -> Helpers.send_error(conn, 412, "Precondition Failed", "No file provided")
    end
  end


  def create(conn, %{}, user) do
    Helpers.send_error(conn, 412, "Precondition Failed", "No file provided")
  end


  def delete(conn, %{"id" => id}, user) do
    opml = from(o in Opml, where: o.id == ^id and
                                  o.user_id == ^user.id,
                           preload: :user)
           |> Repo.one()

    with %PanWeb.Opml{} <- opml do
      File.rm(opml.path)

      opml = Repo.delete!(opml)
             |> mark_if_deleted()

      render conn, "show.json-api", data: opml,
                                    opts: [include: "user"]
    else
      nil -> Helpers.send_404(conn)
    end
  end


  def import(conn, %{"id" => id}, user) do
    opml = from( o in Opml, where: o.id == ^id and
                                   o.user_id == ^user.id,
                            preload: :user)
           |> Repo.one()

    with %PanWeb.Opml{} <- opml do
      Pan.OpmlParser.Opml.parse(opml.path, user.id)

      render conn, "show.json-api", data: opml,
                                    opts: [include: "user"]
    else
      nil -> Helpers.send_404(conn)
    end
  end
end
