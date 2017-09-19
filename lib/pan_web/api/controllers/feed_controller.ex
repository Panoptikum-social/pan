defmodule PanWeb.Api.FeedController do
  use Pan.Web, :controller
  alias PanWeb.Feed
  alias PanWeb.Api.Helpers
  use JaSerializer


  def show(conn, %{"id" => id}) do
    feed = Repo.get(Feed, id)
           |> Repo.preload([:podcast, :alternate_feeds])

    if feed do
      render conn, "show.json-api", data: feed,
                                    opts: [include: "podcast,alternate_feeds"]
    else
      Helpers.send_404(conn)
    end
  end
end
