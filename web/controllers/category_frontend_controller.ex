defmodule Pan.CategoryFrontendController do
  use Pan.Web, :controller

  alias Pan.Category
  alias Pan.Episode
  alias Pan.Podcast
  alias Pan.Subscription

  def index(conn, _params) do
    categories = Repo.all(from category in Category, order_by: :title,
                                                     where: is_nil(category.parent_id))
                 |> Repo.preload(children: from(c in Category, order_by: c.title))

    catcount = Repo.aggregate(Category, :count, :id)
    podcount = Repo.aggregate(Podcast, :count, :id)
    epicount = Repo.aggregate(Episode, :count, :id)

    popular_podcasts = Repo.all(from s in Subscription, join: p in assoc(s, :podcast),
                                                        group_by: p.id,
                                                        select: [count(s.podcast_id), p.id, p.title],
                                                        order_by: [desc: count(s.podcast_id)],
                                                        limit: 10)

    render(conn, "index.html", categories: categories,
                               catcount: catcount,
                               podcount: podcount,
                               epicount: epicount,
                               popular_podcasts: popular_podcasts)
  end


  def show(conn, %{"id" => id}) do
    category = Repo.get!(Category, id)
               |> Repo.preload([podcasts: from(p in Podcast, order_by: p.title),
                                children: from(c in Category, order_by: c.title)])
               |> Repo.preload(:parent)
    render(conn, "show.html", category: category)
  end
end
