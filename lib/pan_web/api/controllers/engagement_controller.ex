defmodule PanWeb.Api.EngagementController do
  use Pan.Web, :controller
  alias PanWeb.{Api.Helpers, Engagement}
  use JaSerializer

  def show(conn, %{"id" => id}) do
    engagement = Repo.get(Engagement, id)
                 |> Repo.preload([:persona, :podcast])

    if engagement do
      render conn, "show.json-api", data: engagement,
                                    opts: [include: "podcast,persona"]
    else
      Helpers.send_404(conn)
    end
  end
end
