defmodule Pan.CategoryApiController do
  use Pan.Web, :controller
  alias Pan.Podcast
  use JaSerializer
  alias Pan.Category

  def index(conn, _params) do
    categories = from(c in Category, order_by: :title,
                                     where: is_nil(c.parent_id))
                 |> Repo.all()
                 |> Repo.preload(children: from(cat in Category, order_by: cat.title))
                 |> Repo.preload(:parent)

    render conn, "index.json-api", data: categories, opts: [include: "children"]
  end


  def show(conn, %{"id" => id} = params) do
    page = Map.get(params, "page", %{})
           |> Map.get("number", "1")
           |> String.to_integer
    size = Map.get(params, "page", %{})
           |> Map.get("size", "10")
           |> String.to_integer
    offset = (page - 1) * size

    total = from(c in Pan.CategoryPodcast, where: c.category_id == ^id)
            |> Repo.aggregate(:count, :category_id)
    total_pages = div(total - 1, size) + 1

    links = JaSerializer.Builder.PaginationLinks.build(%{number: page,
                                                         size: size,
                                                         total: total_pages,
                                                         base_url: category_api_url(conn,:show, id)}, conn)

    category = Repo.get(Category, id)
               |> Repo.preload([:children, :parent])
               |> Repo.preload(podcasts: from(p in Podcast, offset: ^offset, limit: ^size))

    render conn, "show.json-api", data: category, opts: [page: links, include: "podcasts"]
  end
end
