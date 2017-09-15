defmodule PanWeb.FeedApiController do
  use Pan.Web, :controller
  alias PanWeb.Feed
  use JaSerializer


  def show(conn, %{"id" => id}) do
    feed = Repo.get(Feed, id)
           |> Repo.preload([:podcast, :alternate_feeds])

    render conn, "show.json-api", data: feed, opts: [include: "podcast,alternate_feeds"]
  end
end
