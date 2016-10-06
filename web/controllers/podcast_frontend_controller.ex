defmodule Pan.PodcastFrontendController do
  use Pan.Web, :controller

  alias Pan.Podcast

  def index(conn, _params) do
    podcasts = Repo.all(Podcast)
    render(conn, "index.html", podcasts: podcasts)
  end

  def show(conn, %{"id" => id}) do
    podcast = Repo.get!(Podcast, id)
    render(conn, "show.html", podcast: podcast)
  end
end