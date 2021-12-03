defmodule PanWeb.EpisodeFrontendController do
  use PanWeb, :controller
  alias PanWeb.{Chapter, Episode, Recommendation}

  def show(conn, %{"id" => id}) do
    episode =
      Repo.get!(Episode, id)
      |> Repo.preload([:podcast, :enclosures, gigs: :persona, recommendations: :user])
      |> Repo.preload(
        chapters:
          from(chapter in Chapter,
            order_by: chapter.start,
            preload: [recommendations: :user]
          )
      )

    changeset = Recommendation.changeset(%Recommendation{})
    # options for player: "podlove", "podigee"
    render(conn, "show.html",
      episode: episode,
      player: "podlove",
      changeset: changeset
    )
  end

  def player(conn, %{"id" => id}) do
    episode =
      Repo.get!(Episode, id)
      |> Repo.preload([:podcast, :enclosures, gigs: :persona, recommendations: :user])
      |> Repo.preload(chapters: from(chapter in Chapter, order_by: chapter.start))

    # options for player: "podlove", "podigee"
    conn
    |> put_layout("minimal.html")
    |> render("player.html",
      episode: episode,
      player: "podlove"
    )
  end

  def silence(conn, _params) do
    # Just here to silence a weird request from the podlove webplayer
    text(conn, nil)
  end
end
