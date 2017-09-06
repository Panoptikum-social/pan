defmodule PanWeb.EnclosureApiController do
  use Pan.Web, :controller
  use JaSerializer
  alias PanWeb.Enclosure


  def show(conn, %{"id" => id}) do

    enclosure = Repo.get(Enclosure, id)
                |> Repo.preload(:episode)

    render conn, "show.json-api", data: enclosure,
                                  opts: [include: "episode"]
  end
end
