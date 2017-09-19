defmodule PanWeb.Api.OpmlController do
  use Pan.Web, :controller
  alias PanWeb.Opml
  use JaSerializer
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
                           preload: :user)

    render conn, "show.json-api", data: opml,
                                  opts: [include: "user"]
  end


  def create(conn, %{"upload" => upload}, user) do
    destination_path =
      if upload do
        File.mkdir_p("/var/phoenix/pan-uploads/opml/#{user.id}")
        path = "/var/phoenix/pan-uploads/opml/#{user.id}/#{upload.filename}"
        File.cp(upload.path, path)
        path
      else
        ""
      end

    {:ok, opml} = %Opml{content_type: upload.content_type,
                        filename: upload.filename,
                        path: destination_path,
                        user_id: user.id}
                  |> Opml.changeset()
                  |> Repo.insert()

    opml = Repo.preload(opml, :user)

    render conn, "show.json-api", data: opml,
                                  opts: [include: "user"]
  end


  def delete(conn, %{"id" => id}, user) do
    opml = from(o in Opml, where: o.id == ^id and
                                  o.user_id == ^user.id,
                           preload: :user)
           |> Repo.one()

    File.rm(opml.path)

    opml = Repo.delete!(opml)
           |> mark_if_deleted()

    render conn, "show.json-api", data: opml,
                                  opts: [include: "user"]
  end


  def import(conn, %{"id" => id}, user) do
    opml = from( o in Opml, where: o.id == ^id and
                                   o.user_id == ^user.id,
                            preload: :user)
           |> Repo.one()

    Pan.OpmlParser.Opml.parse(opml.path, user.id)

    render conn, "show.json-api", data: opml,
                                  opts: [include: "user"]
  end
end
