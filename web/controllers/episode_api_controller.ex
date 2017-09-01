defmodule Pan.EpisodeApiController do
  use Pan.Web, :controller
  use JaSerializer
  alias Pan.Chapter
  alias Pan.Episode


  def show(conn, %{"id" => id} = params) do

    episode = Repo.get(Episode, id)
              |> Repo.preload([:podcast, :chapters, [recommendations: :user]])

    render conn, "show.json-api", data: episode,
                                  opts: [include: "podcast,chapters,recommendations"]
  end
end
