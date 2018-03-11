defmodule PanWeb.EpisodeFrontendController do
  use Pan.Web, :controller

  alias PanWeb.Episode
  alias PanWeb.Chapter
  alias PanWeb.Recommendation

  def show(conn, %{"id" => id}) do
    episode = Repo.get!(Episode, id)
              |> Repo.preload([:podcast, :enclosures, gigs: :persona, recommendations: :user])
              |> Repo.preload(chapters: from(chapter in Chapter, order_by: chapter.start,
                                                                 preload: [recommendations: :user]))

    changeset = Recommendation.changeset(%Recommendation{})
    # options for player: "podlove", "podigee"
    render(conn, "show.html", episode: episode, player: "podlove", changeset: changeset)
  end


  def player(conn, %{"id" => id}) do
    episode = Repo.get!(Episode, id)
              |> Repo.preload([:podcast, :enclosures, gigs: :persona, recommendations: :user])
              |> Repo.preload(chapters: from(chapter in Chapter, order_by: chapter.start))

    # options for player: "podlove", "podigee"
    conn
    |> put_layout("minimal.html")
    |> render("player.html", episode: episode, player: "podlove")
  end


  def index(conn, params) do
    episodes = from(e in Episode, join: p in assoc(e, :podcast),
                                  where: (is_nil(p.blocked) or p.blocked == false) and
                                   e.publishing_date < ^NaiveDateTime.utc_now(),
                                  order_by: [desc: :publishing_date],
                                  preload: [:podcast])
               |> Repo.paginate(page: params["page"], page_size: 10)

    render(conn, "index.html", episodes: episodes)
  end

  def silence(conn, _params) do
    # Just here to silence a weird request from the podlove webplayer
    text conn, nil
  end
end