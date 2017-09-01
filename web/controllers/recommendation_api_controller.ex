defmodule Pan.RecommendationApiController do
  use Pan.Web, :controller
  alias Pan.Recommendation
  use JaSerializer


  def show(conn, %{"id" => id}) do
    recommendation = Repo.get(Recommendation, id)
                     |> Repo.preload([:podcast, :episode, :chapter, :user])

    render conn, "show.json-api", data: recommendation,
                                  opts: [include: "podcast,episode,chapter"]
  end
end
