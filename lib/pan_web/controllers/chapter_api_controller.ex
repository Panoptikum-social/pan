defmodule PanWeb.ChapterApiController do
  use Pan.Web, :controller
  use JaSerializer
  alias PanWeb.Chapter


  def show(conn, %{"id" => id}) do

    chapter = Repo.get(Chapter, id)
              |> Repo.preload([:episode, [recommendations: :user]])

    render conn, "show.json-api", data: chapter,
                                  opts: [include: "episode,recommendations"]
  end
end
