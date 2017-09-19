defmodule PanWeb.Api.CategoryController do
  use Pan.Web, :controller
  use JaSerializer
  alias PanWeb.Podcast
  alias PanWeb.Category
  alias PanWeb.CategoryPodcast
  alias PanWeb.Subscription
  alias PanWeb.Api.Helpers

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end


  def index(conn, _params, _user) do
    categories = from(c in Category, order_by: :title,
                                     where: is_nil(c.parent_id))
                 |> Repo.all()
                 |> Repo.preload(children: from(cat in Category, order_by: cat.title))
                 |> Repo.preload(:parent)

    render conn, "index.json-api", data: categories, opts: [include: "children"]
  end


  def show(conn, %{"id" => id} = params, _user) do
    page = Map.get(params, "page", %{})
           |> Map.get("number", "1")
           |> String.to_integer
    size = Map.get(params, "page", %{})
           |> Map.get("size", "10")
           |> String.to_integer
    offset = (page - 1) * size

    total = from(c in PanWeb.CategoryPodcast, where: c.category_id == ^id)
            |> Repo.aggregate(:count, :category_id)
    total_pages = div(total - 1, size) + 1

    links = JaSerializer.Builder.PaginationLinks.build(%{number: page,
                                                         size: size,
                                                         total: total_pages,
                                                         base_url: category_url(conn,:show, id)}, conn)

    category = Repo.get(Category, id)
               |> Repo.preload([:children, :parent])
               |> Repo.preload(podcasts:
                   from(p in Podcast, offset: ^offset,
                                      order_by: [fragment("? DESC NULLS LAST", p.latest_episode_publishing_date)],
                                      limit: ^size))

    if category do
      render conn, "show.json-api", data: category, opts: [page: links, include: "podcasts"]
    else
      Helpers.send_404(conn)
    end
  end


  def search(conn, params, _user) do
    query = [index: "/panoptikum_" <> Application.get_env(:pan, :environment) <> "/categories",
             search: [size: 1000, query: [match: [_all: params["filter"]]]]]


    case Tirexs.Query.create_resource(query) do
      {:ok, 200, %{hits: hits}} ->
        category_ids = Enum.map(hits[:hits], fn(hit) -> String.to_integer(hit[:_id]) end)

        categories = from(c in Category, where: c.id in ^category_ids)
                     |> Repo.all()
                     |> Repo.preload(children: from(cat in Category, order_by: cat.title))
                     |> Repo.preload(:parent)

        render conn, "index.json-api", data: categories, opts: [include: "children"]
      {:error, 500, %{error: %{caused_by: %{reason: reason}}}} ->
        render(conn, "error.json-api", reason: reason)
    end
  end


  def my(conn, _params, user) do
    podcasts_subscribed_ids = from(s in Subscription, where: s.user_id == ^user.id,
                                                      select: s.podcast_id)
                              |> Repo.all()

    category_ids = from(r in CategoryPodcast, join: c in assoc(r, :category),
                                             where: r.podcast_id in ^podcasts_subscribed_ids,
                                             group_by: c.id,
                                             select: c.id,
                                             order_by: [desc: count(r.category_id)],
                                             limit: 10)
                  |> Repo.all()

    categories = from(c in Category, where: c.id in ^category_ids,
                                     preload: [:children, :parent])
               |> Repo.all()

    render conn, "index.json-api", data: categories, opts: [include: "children"]
  end
end
