defmodule Pan.RecommendationApiController do
  use Pan.Web, :controller
  alias Pan.Recommendation
  use JaSerializer


  def show(conn, %{"id" => id}) do
    recommendation = Repo.get(Recommendation, id)
                     |> Repo.preload(:podcast)

    render conn, "show.json-api", data: recommendation
  end
end
