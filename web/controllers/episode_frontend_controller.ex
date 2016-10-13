defmodule Pan.EpisodeFrontendController do
  use Pan.Web, :controller

  alias Pan.Episode
  alias Pan.Chapter

  def show(conn, %{"id" => id}) do
    episode = Repo.get!(Episode, id)
    episode = Repo.preload(episode, [:podcast, :enclosures, :contributors])
    episode = Repo.preload(episode, chapters: from(chapter in Chapter, order_by: chapter.start))
    render(conn, "show.html", episode: episode)
  end

  def player(conn, %{"id" => id}) do
    episode = Repo.get!(Episode, id)
    episode = Repo.preload(episode, [:podcast, :enclosures, :contributors])
    episode = Repo.preload(episode, chapters: from(chapter in Chapter, order_by: chapter.start))
    conn
    |> put_layout("minimal.html")
    |> render("player.html", episode: episode )
  end

  def latest(conn, _params) do
    episodes = Repo.all(from e in Episode, order_by: [desc: :publishing_date],
                                           limit: 10)
               |> Repo.preload(:podcast)
    render(conn, "latest.html", episodes: episodes)
  end
end