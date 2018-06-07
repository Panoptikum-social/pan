defmodule PanWeb.PageFrontendController do
  use Pan.Web, :controller
  alias PanWeb.Podcast

  def home(conn, _params) do
    popular_podcasts = (from p in Podcast, select: [p.subscriptions_count, p.id, p.title],
                                           order_by: [fragment("? DESC NULLS LAST", p.subscriptions_count)],
                                           limit: 10)
                       |> Repo.all()

    liked_podcasts = (from p in Podcast, select: [p.likes_count, p.id, p.title],
                                         order_by: [fragment("? DESC NULLS LAST", p.likes_count)],
                                         limit: 5)
                     |> Repo.all()

    render(conn, "home.html", popular_podcasts: popular_podcasts,
                              liked_podcasts: liked_podcasts)
  end


  def pro_features(conn, _params) do
    render(conn, "pro_features.html")
  end
end
