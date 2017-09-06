defmodule PanWeb.PageFrontendController do
  use Pan.Web, :controller

  alias PanWeb.Subscription
  alias PanWeb.Like

  def home(conn, _params) do
    popular_podcasts = ConCache.get_or_store(:slow_cache, :popular_podcasts, fn() ->
                         (from s in Subscription, join: p in assoc(s, :podcast),
                                                  group_by: p.id,
                                                  select: [count(s.podcast_id), p.id, p.title],
                                                  order_by: [desc: count(s.podcast_id)],
                                                  limit: 10)
                         |> Repo.all()
                       end)

    liked_podcasts = ConCache.get_or_store(:slow_cache, :liked_podcasts, fn() ->
                         (from l in Like, join: p in assoc(l, :podcast),
                                          group_by: p.id,
                                          select: [count(l.podcast_id), p.id, p.title],
                                          order_by: [desc: count(l.podcast_id)],
                                          limit: 5)
                         |> Repo.all()
                       end)

    render(conn, "home.html", popular_podcasts: popular_podcasts,
                              liked_podcasts: liked_podcasts)
  end


  def pro_features(conn, _params) do
    render(conn, "pro_features.html")
  end
end
