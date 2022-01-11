defmodule PanWeb.PodcastFrontendController do
  use PanWeb, :controller
  alias PanWeb.Podcast

  def feeds(conn, %{"id" => id}) do
    podcast =
      Repo.get!(Podcast, id)
      |> Repo.preload(feeds: :alternate_feeds)

    render(conn, "feeds.html", podcast: podcast)
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
