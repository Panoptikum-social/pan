defmodule Pan.EngagementApiController do
  use Pan.Web, :controller
  alias Pan.Engagement
  use JaSerializer

  def show(conn, %{"id" => id}) do
    engagement = Repo.get(Engagement, id)
                 |> Repo.preload([:persona, :podcast])

    render conn, "show.json-api", data: engagement, opts: [include: "podcast,persona"]
  end
end
