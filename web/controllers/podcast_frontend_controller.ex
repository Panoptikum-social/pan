defmodule Pan.PodcastFrontendController do
  use Pan.Web, :controller
  alias Pan.Podcast
  alias Pan.Episode

  def index(conn, _params) do
    podcasts = Repo.all(Podcast)
               |> Repo.preload(:categories)
    render(conn, "index.html", podcasts: podcasts)
  end


  def show(conn, %{"id" => id}) do
    podcast = get_with_relations id
    render(conn, "show.html", podcast: podcast)
  end


  def subscribe_button(conn, %{"id" => id}) do
    podcast = Repo.get!(Podcast, id)
    podcast = Repo.preload(podcast, :feeds)
    render(conn, "subscribe_button.html", podcast: podcast)
  end


  defp get_with_relations(id) do
    Repo.get!(Podcast, id)
    |> Repo.preload([:languages, :owner, :feeds])
    |> Repo.preload(episodes: from(episode in Episode, order_by: [desc: episode.publishing_date]))
  end
end
