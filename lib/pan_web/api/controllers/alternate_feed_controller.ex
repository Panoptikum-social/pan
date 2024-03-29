defmodule PanWeb.Api.AlternateFeedController do
  use PanWeb, :controller
  alias PanWeb.{AlternateFeed, Api.Helpers}
  use JaSerializer

  def show(conn, %{"id" => id}) do
    alternate_feed =
      AlternateFeed
      |> Repo.get(id)
      |> Repo.preload([:feed])

    if alternate_feed do
      render(conn, "show.json-api", data: alternate_feed)
    else
      Helpers.send_404(conn)
    end
  end
end
