defmodule Pan.CategoryFrontendController do
  use Pan.Web, :controller

  alias Pan.Category
  alias Pan.Episode
  alias Pan.Podcast

  def index(conn, _params) do
    categories = Repo.all(from category in Category, order_by: :title,
                                                     where: is_nil(category.parent_id))
                 |> Repo.preload(children: from(c in Category, order_by: c.title))

    catcount = Repo.aggregate(Category, :count, :id)
    podcount = Repo.aggregate(Podcast, :count, :id)
    epicount = Repo.aggregate(Episode, :count, :id)

    render(conn, "index.html", categories: categories,
                               catcount: catcount,
                               podcount: podcount,
                               epicount: epicount)
  end


  def show(conn, %{"id" => id}) do
    category = Repo.get!(Category, id)
               |> Repo.preload([podcasts: from(p in Podcast, order_by: p.title),
                                children: from(c in Category, order_by: c.title)])
               |> Repo.preload(:parent)
    render(conn, "show.html", category: category)
  end
end
