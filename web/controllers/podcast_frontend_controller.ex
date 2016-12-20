defmodule Pan.PodcastFrontendController do
  use Pan.Web, :controller
  alias Pan.Podcast
  alias Pan.Episode
  alias Pan.Recommendation

  def index(conn, params) do
    query = from p in Podcast, order_by: [desc: :inserted_at],
                               preload: [:categories]

    podcasts = query
               |> Ecto.Queryable.to_query
               |> Repo.paginate(params)

    render(conn, "index.html", podcasts: podcasts)
  end


  def button_index(conn, _params) do
    podcasts = Repo.all(Podcast)
    render(conn, "button_index.html", podcasts: podcasts)
  end


  def show(conn, %{"id" => id}) do
    changeset = Recommendation.changeset(%Recommendation{})
    podcast = get_with_relations id
    render(conn, "show.html", podcast: podcast, changeset: changeset)
  end


  def subscribe_button(conn, %{"id" => id}) do
    podcast = Repo.get!(Podcast, id)
    podcast = Repo.preload(podcast, :feeds)
    render(conn, "subscribe_button.html", podcast: podcast)
  end


  defp get_with_relations(id) do
    Repo.get!(Podcast, id)
    |> Repo.preload([:languages, :owner, :feeds, :categories, recommendations: :user])
    |> Repo.preload(episodes: from(episode in Episode, order_by: [desc: episode.publishing_date]))
  end
end
