defmodule Pan.CategoryFrontendController do
  use Pan.Web, :controller

  alias Pan.Category

  def index(conn, _params) do
    categories = Repo.all(from category in Category, where: is_nil(category.parent_id))
                 |> Repo.preload([:podcasts, :children])
    render(conn, "index.html", categories: categories)
  end

  def show(conn, %{"id" => id}) do
    category = Repo.get!(Category, id)
               |> Repo.preload([:podcasts, :children])
    render(conn, "show.html", category: category)
  end
end
