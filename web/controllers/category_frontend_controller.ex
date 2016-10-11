defmodule Pan.CategoryFrontendController do
  use Pan.Web, :controller

  alias Pan.Category
  alias Pan.Episode
  alias Pan.Podcast

  def index(conn, _params) do
    categories = Repo.all(from category in Category, where: is_nil(category.parent_id))
                 |> Repo.preload([:podcasts, :children])

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
               |> Repo.preload([:podcasts, :children])
    render(conn, "show.html", category: category)
  end
end
