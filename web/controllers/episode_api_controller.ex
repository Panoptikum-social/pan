defmodule Pan.EpisodeApiController do
  use Pan.Web, :controller
  use JaSerializer
  alias Pan.Episode


  def show(conn, %{"id" => id}) do

    episode = Repo.get(Episode, id)
              |> Repo.preload([:podcast, :chapters, [recommendations: :user], :enclosures, :gigs,
                               :contributors])

    render conn, "show.json-api", data: episode,
                                  opts: [include: "podcast,chapters,recommendations,enclosures,gigs,contributors"]
  end
end
