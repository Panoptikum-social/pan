defmodule Pan.CategoryApiController do
  use Pan.Web, :controller
  alias Pan.Category

  def index(conn, _params) do
    categories = from(c in Category, order_by: :title,
                                     where: is_nil(c.parent_id))
                 |> Repo.all()
                 |> Repo.preload(children: from(cat in Category, order_by: cat.title))

    render conn, "index.json-api", data: categories
  end

  def show(conn, %{"id" => id}) do
    category = Repo.get(Category, id)
               |> Repo.preload([:children, :parent])

    render conn, "show.json-api", data: category
  end
end