defmodule Pan.PageFrontendController do
  use Pan.Web, :controller

  alias Pan.Category
  alias Pan.Subscription

  def home(conn, _params) do
    popular_podcasts = ConCache.get_or_store(:slow_cache, :popular_podcasts, fn() ->
                         (from s in Subscription, join: p in assoc(s, :podcast),
                                                  group_by: p.id,
                                                  select: [count(s.podcast_id), p.id, p.title],
                                                  order_by: [desc: count(s.podcast_id)],
                                                  limit: 10)
                         |> Repo.all()
                       end)

    render(conn, "home.html", popular_podcasts: popular_podcasts)
  end
end
