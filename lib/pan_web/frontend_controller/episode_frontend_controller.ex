defmodule PanWeb.EpisodeFrontendController do
  use PanWeb, :controller
  alias PanWeb.{Chapter, Episode, Recommendation}

  def player(conn, %{"id" => id}) do
    episode =
      Repo.get!(Episode, id)
      |> Repo.preload([:podcast, :enclosures, gigs: :persona, recommendations: :user])
      |> Repo.preload(chapters: from(chapter in Chapter, order_by: chapter.start))

    conn
    |> put_layout("minimal.html")
    |> render("player.html", episode: episode)
  end

  def silence(conn, _params) do
    # Just here to silence a weird request from the podlove webplayer
    text(conn, nil)
  end
end
