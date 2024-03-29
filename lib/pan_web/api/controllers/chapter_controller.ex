defmodule PanWeb.Api.ChapterController do
  use PanWeb, :controller
  use JaSerializer
  alias PanWeb.{Api.Helpers, Chapter}

  def show(conn, %{"id" => id}) do
    chapter =
      Repo.get(Chapter, id)
      |> Repo.preload([:episode, [recommendations: :user]])

    if chapter do
      render(conn, "show.json-api",
        data: chapter,
        opts: [include: "episode,recommendations"]
      )
    else
      Helpers.send_404(conn)
    end
  end
end
