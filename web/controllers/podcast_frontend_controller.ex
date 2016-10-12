defmodule Pan.PodcastFrontendController do
  use Pan.Web, :controller

  alias Pan.Podcast
  alias Pan.Episode


  def index(conn, _params) do
    podcasts = Repo.all(Podcast)
    podcasts = Repo.preload(podcasts, [:categories])
    render(conn, "index.html", podcasts: podcasts)
  end


  def show(conn, %{"id" => id}) do
    podcast = Repo.get!(Podcast, id)
    podcast = Repo.preload(podcast, [:language, :owner, :feeds])
    podcast = Repo.preload(podcast, episodes: from(episode in Episode, order_by: [desc: episode.publishing_date]))
    render(conn, "show.html", podcast: podcast)
  end


  def subscribe_button(conn, %{"id" => id}) do
    podcast = Repo.get!(Podcast, id)
    podcast = Repo.preload(podcast, :feeds)
    render(conn, "subscribe_button.html", podcast: podcast)
  end
end