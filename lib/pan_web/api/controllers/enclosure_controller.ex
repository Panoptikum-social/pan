defmodule PanWeb.Api.EnclosureController do
  use Pan.Web, :controller
  use JaSerializer
  alias PanWeb.{Api.Helpers, Enclosure}

  def show(conn, %{"id" => id}) do
    enclosure =
      Repo.get(Enclosure, id)
      |> Repo.preload(:episode)

    if enclosure do
      render(conn, "show.json-api",
        data: enclosure,
        opts: [include: "episode"]
      )
    else
      Helpers.send_404(conn)
    end
  end
end
