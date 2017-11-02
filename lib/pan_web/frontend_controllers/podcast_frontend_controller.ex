defmodule PanWeb.PodcastFrontendController do
  use Pan.Web, :controller
  alias PanWeb.Podcast
  alias PanWeb.Episode
  alias PanWeb.Recommendation
  alias PanWeb.Gig

  def index(conn, params) do
    podcasts = from(p in Podcast, order_by: [desc: :inserted_at],
                                  where: is_nil(p.blocked) or p.blocked == false,
                                  preload: [:categories, [engagements: :persona]])
               |> Repo.paginate(params)

    render(conn, "index.html", podcasts: podcasts)
  end


  def button_index(conn, _params) do
    podcasts = Repo.all(Podcast)
    render(conn, "button_index.html", podcasts: podcasts)
  end


  def show(conn, %{"id" => id}) do
    changeset = Recommendation.changeset(%Recommendation{})
    podcast =  Repo.get!(Podcast, id)
               |> Repo.preload([:languages, :feeds, :categories, recommendations: :user])
               |> Repo.preload(episodes: from(episode in Episode, order_by: [desc: episode.publishing_date]))
               |> Repo.preload(episodes: [gigs: :persona])
               |> Repo.preload([engagements: :persona])

    render(conn, "show.html", podcast: podcast,
                              changeset: changeset)
  end


  def subscribe_button(conn, %{"id" => id}) do
    podcast = Repo.get!(Podcast, id)
              |> Repo.preload(:feeds)

    conn
    |> render("_subscribe_button.html", podcast: podcast)
  end


  def feeds(conn, %{"id" => id}) do
    podcast =  Repo.get!(Podcast, id)
               |> Repo.preload([feeds: :alternate_feeds])

    render(conn, "feeds.html", podcast: podcast)
  end
end