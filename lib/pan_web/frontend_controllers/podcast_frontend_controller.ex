defmodule PanWeb.PodcastFrontendController do
  use Pan.Web, :controller
  alias PanWeb.{Episode, Image, Podcast, Recommendation}

  def index(conn, params) do
    podcasts = from(p in Podcast, order_by: [desc: :inserted_at],
                                  where: is_nil(p.blocked) or p.blocked == false,
                                  preload: [:categories, [engagements: :persona]])
               |> Repo.paginate(page: params["page"], page_size: 10)

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
               |> Repo.preload(episodes: :thumbnails)
               |> Repo.preload([engagements: :persona])

    podcast_thumbnail = from(i in Image, where: i.podcast_id == ^podcast.id)
                        |> Repo.one()

    render(conn, "show.html", podcast: podcast,
                              podcast_thumbnail: podcast_thumbnail,
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


  def trigger_update(conn, %{"id" => id}) do
    id = String.to_integer(id)
    podcast = Repo.get!(Podcast, id)

    if !podcast.manually_updated_at or
       (Timex.compare(Timex.shift(podcast.manually_updated_at, hours: 1), Timex.now()) == -1) do

      podcast
      |> Podcast.changeset(%{manually_updated_at: Timex.now()})
      |> Repo.update()

      Task.async(fn -> Pan.Parser.Podcast.update_from_feed(id) end)
      conn
      |> put_flash(:info, "Podcast metadata update started")
    else
      conn
      |> put_flash(:error, "This podcast has been updated manually within the last hour. Please try again in an hour.")
    end
    |> redirect(to: podcast_frontend_path(conn, :show, id))
  end
end