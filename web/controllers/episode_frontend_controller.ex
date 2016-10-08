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
end