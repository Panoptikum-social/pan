defmodule PanWeb.OpmlApiController do
  use Pan.Web, :controller
  alias PanWeb.Opml
  use JaSerializer

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
end
