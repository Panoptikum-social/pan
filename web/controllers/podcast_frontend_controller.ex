defmodule Pan.PodcastFrontendController do
  use Pan.Web, :controller
  alias Pan.Podcast
  alias Pan.Episode
  alias Pan.Recommendation
  alias Pan.Engagement

  def index(conn, params) do
    podcasts = from(p in Podcast, order_by: [desc: :inserted_at],
                                  where: is_nil(p.blocked) or p.blocked == false,
                                  preload: [:categories])
               |> Repo.paginate(params)

    render(conn, "index.html", podcasts: podcasts)
  end


  def button_index(conn, _params) do
    podcasts = Repo.all(Podcast)
    render(conn, "button_index.html", podcasts: podcasts)
  end


  def show(conn, %{"id" => id}) do
    changeset = Recommendation.changeset(%Recommendation{})
    podcast =  Repo.get(Podcast, id)
               |> Repo.preload([:languages, :feeds, :categories, recommendations: :user])
               |> Repo.preload(episodes: from(episode in Episode, order_by: [desc: episode.publishing_date]))
               |> Repo.preload(engagements: from(e in Engagement, where: e.role == "owner"))
               |> Repo.preload([engagements: :persona])

    render(conn, "show.html", podcast: podcast, changeset: changeset)
  end


  def subscribe_button(conn, %{"id" => id}) do
    podcast = Repo.get!(Podcast, id)
    podcast = Repo.preload(podcast, :feeds)

    conn
    |> render("_subscribe_button.html", podcast: podcast)
  end


  defp get_with_relations(id) do

  end
end
