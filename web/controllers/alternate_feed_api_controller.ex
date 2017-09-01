defmodule Pan.AlternateFeedApiController do
  use Pan.Web, :controller
  alias Pan.AlternateFeed
  use JaSerializer


  def show(conn, %{"id" => id}) do
    alternate_feed = Repo.get(AlternateFeed, id)
                     |> Repo.preload([:feed])

    render conn, "show.json-api", data: alternate_feed
  end
end
