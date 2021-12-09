defmodule PanWeb.PodcastFrontendController do
  use PanWeb, :controller
  alias PanWeb.Podcast

  def subscribe_button(conn, %{"id" => id}) do
    podcast =
      Repo.get!(Podcast, id)
      |> Repo.preload(:feeds)

    conn
    |> render("_subscribe_button.html", podcast: podcast)
  end

  def feeds(conn, %{"id" => id}) do
    podcast =
      Repo.get!(Podcast, id)
      |> Repo.preload(feeds: :alternate_feeds)

    render(conn, "feeds.html", podcast: podcast)
  end

  def trigger_update(conn, %{"id" => id}) do
    podcast = Repo.get!(Podcast, id)

    if !podcast.manually_updated_at or
         Timex.compare(Timex.shift(podcast.manually_updated_at, hours: 1), Timex.now()) == -1 do
      podcast
      |> Podcast.changeset(%{manually_updated_at: Timex.now()})
      |> Repo.update()

      Pan.Parser.Podcast.update_from_feed(podcast)

      conn
      |> put_flash(:info, "Podcast metadata update started")
    else
      conn
      |> put_flash(
        :error,
        "This podcast has been updated manually within the last hour. Please try again in an hour."
      )
    end
    |> redirect(to: podcast_frontend_path(conn, :show, podcast.id))
  end

  def liked(conn, _params) do
    liked_podcasts =
      from(p in Podcast,
        select: [p.likes_count, p.id, p.title],
        order_by: [fragment("? DESC NULLS LAST", p.likes_count)],
        limit: 100
      )
      |> Repo.all()

    render(conn, "liked.html", liked_podcasts: liked_podcasts)
  end

  def popular(conn, _params) do
    popular_podcasts =
      from(p in Podcast,
        select: [p.subscriptions_count, p.id, p.title],
        order_by: [fragment("? DESC NULLS LAST", p.subscriptions_count)],
        limit: 100
      )
      |> Repo.all()

    render(conn, "popular.html", popular_podcasts: popular_podcasts)
  end
end
