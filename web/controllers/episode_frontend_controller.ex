defmodule Pan.EpisodeFrontendController do
  use Pan.Web, :controller

  alias Pan.Episode
  alias Pan.Chapter
  alias Pan.Recommendation

  def show(conn, %{"id" => id}) do
    episode = Repo.get!(Episode, id)
    episode = Repo.preload(episode, [:podcast, :enclosures, :contributors, recommendations: :user])
    episode = Repo.preload(episode, chapters: from(chapter in Chapter, order_by: chapter.start,
                                                                       preload: [recommendations: :user]))

    changeset = Recommendation.changeset(%Recommendation{})
    # options for player: "podlove", "podigee"
    render(conn, "show.html", episode: episode, player: "podigee", changeset: changeset)
  end


  def player(conn, %{"id" => id}) do
    episode = Repo.get!(Episode, id)
              |> Repo.preload([:podcast, :enclosures, :contributors])
              |> Repo.preload(chapters: from(chapter in Chapter, order_by: chapter.start))

    # options for player: "podlove", "podigee"
    conn
    |> put_layout("minimal.html")
    |> render("player.html", episode: episode, player: "podigee" )
  end


  def index(conn, params) do
    episodes = from(e in Episode, order_by: [desc: :publishing_date],
                               preload: [:podcast])
               |> Repo.paginate(params)

    render(conn, "index.html", episodes: episodes)
  end
end