defmodule PanWeb.EpisodeFrontendController do
  use Pan.Web, :controller
  alias PanWeb.{Chapter, Episode, Image, Recommendation}

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

    episode_thumbnail =
      Repo.get_by(Image, episode_id: episode.id) ||
        Repo.get_by(Image, podcast_id: episode.podcast.id)

    changeset = Recommendation.changeset(%Recommendation{})
    # options for player: "podlove", "podigee"
    render(conn, "show.html",
      episode: episode,
      episode_thumbnail: episode_thumbnail,
      player: "podlove",
      changeset: changeset
    )
  end

  def player(conn, %{"id" => id}) do
    episode =
      Repo.get!(Episode, id)
      |> Repo.preload([:podcast, :enclosures, gigs: :persona, recommendations: :user])
      |> Repo.preload(chapters: from(chapter in Chapter, order_by: chapter.start))

    episode_thumbnail =
      Repo.get_by(Image, episode_id: episode.id) ||
        Repo.get_by(Image, podcast_id: episode.podcast.id)

    # options for player: "podlove", "podigee"
    conn
    |> put_layout("minimal.html")
    |> render("player.html",
      episode: episode,
      episode_thumbnail: episode_thumbnail,
      player: "podlove"
    )
  end

  def index(conn, params) do
    episode_ids =
      from(e in Episode,
        order_by: [desc: :id],
        select: e.id
      )
      |> Repo.paginate(
        page: params["page"],
        page_size: 10,
        options: [total_entries: total_estimated(Episode)]
      )

    episodes =
      from(e in Episode,
        join: p in assoc(e, :podcast),
        where:
          e.id in ^episode_ids.entries and
            is_false(p.blocked),
        order_by: [desc: :id],
        preload: :podcast
      )
      |> Repo.all()

    render(conn, "index.html", episode_ids: episode_ids, episodes: episodes)
  end

  def silence(conn, _params) do
    # Just here to silence a weird request from the podlove webplayer
    text(conn, nil)
  end
end
