defmodule Pan.EnclosureApiController do
  use Pan.Web, :controller
  use JaSerializer
  alias Pan.Enclosure


  def show(conn, %{"id" => id}) do

    enclosure = Repo.get(Enclosure, id)
                |> Repo.preload(:episode)

    render conn, "show.json-api", data: enclosure,
                                  opts: [include: "episode"]
  end
end
