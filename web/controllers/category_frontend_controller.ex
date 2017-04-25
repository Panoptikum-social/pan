defmodule Pan.CategoryFrontendController do
  use Pan.Web, :controller

  alias Pan.Category
  alias Pan.Podcast
  alias Pan.Subscription

  def index(conn, _params) do
    categories = ConCache.get_or_store(:slow_cache, :categories, fn() ->
                   (from c in Category, order_by: :title,
                                        where: is_nil(c.parent_id))
                   |> Repo.all()
                   |> Repo.preload(children: from(cat in Category, order_by: cat.title))
                 end)

    popular_podcasts = ConCache.get_or_store(:slow_cache, :popular_podcasts, fn() ->
                         (from s in Subscription, join: p in assoc(s, :podcast),
                                                  group_by: p.id,
                                                  select: [count(s.podcast_id), p.id, p.title],
                                                  order_by: [desc: count(s.podcast_id)],
                                                  limit: 10)
                         |> Repo.all()
                       end)

    render(conn, "index.html", popular_podcasts: popular_podcasts,
                               categories: categories)
  end


  def show(conn, %{"id" => id}) do
    category = Category
               |> Repo.get!(id)
               |> Repo.preload([podcasts: from(p in Podcast, order_by: p.title),
                                children: from(c in Category, order_by: c.title)])
               |> Repo.preload(:parent)
               |> Repo.preload(podcasts: :languages)
    render(conn, "show.html", category: category)
  end
end
