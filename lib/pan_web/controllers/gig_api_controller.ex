defmodule PanWeb.GigApiController do
  use Pan.Web, :controller
  alias PanWeb.Gig
  use JaSerializer

  def show(conn, %{"id" => id}) do
    gig = Repo.get(Gig, id)
          |> Repo.preload([:persona, :episode])

    render conn, "show.json-api", data: gig, opts: [include: "episode,persona"]
  end
end
