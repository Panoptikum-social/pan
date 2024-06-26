defmodule PanWeb.Api.CategoryController do
  use PanWeb, :controller
  use JaSerializer
  alias PanWeb.{Api.Helpers, Category, CategoryPodcast, Podcast, Subscription}

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end

  def index(conn, _params, _user) do
    categories =
      from(c in Category,
        order_by: :title,
        where: is_nil(c.parent_id)
      )
      |> Repo.all()
      |> Repo.preload(children: from(cat in Category, order_by: cat.title))
      |> Repo.preload(:parent)

    render(conn, "index.json-api", data: categories, opts: [include: "children"])
  end

  def show(conn, %{"id" => id} = params, _user) do
    page =
      if is_map(params["page"]) do
        get_in(params, ["page", "number"]) || "1"
      else
        "1"
      end
      |> String.to_integer()

    size =
      if is_map(params["page"]) do
        get_in(params, ["page", "size"]) || "10"
      else
        "10"
      end
      |> String.to_integer()
      |> min(1000)

    offset = (page - 1) * size

    total =
      from(c in PanWeb.CategoryPodcast, where: c.category_id == ^id)
      |> Repo.aggregate(:count, :category_id)

    total_pages = div(total - 1, size) + 1

    links =
      conn
      |> api_category_url(:show, id)
      |> Helpers.pagination_links({page, size, total_pages}, conn)

    category =
      Repo.get(Category, id)
      |> Repo.preload([:children, :parent])
      |> Repo.preload(
        podcasts:
          from(p in Podcast,
            offset: ^offset,
            order_by: [fragment("? DESC NULLS LAST", p.latest_episode_publishing_date)],
            limit: ^size
          )
      )

    if category do
      render(conn, "show.json-api", data: category, opts: [page: links, include: "podcasts"])
    else
      Helpers.send_404(conn)
    end
  end

  def search(conn, params, _user) do
    hits = Pan.Search.query(index: "categories", term: params["filter"], limit: 1000, offset: 0)

    if hits["total"] > 0 do
      category_ids = Enum.map(hits["hits"], fn hit -> String.to_integer(hit["_id"]) end)

      categories =
        from(c in Category, where: c.id in ^category_ids)
        |> Repo.all()
        |> Repo.preload(children: from(cat in Category, order_by: cat.title))
        |> Repo.preload(:parent)

      render(conn, "index.json-api", data: categories, opts: [include: "children"])
    else
      Helpers.send_error(
        conn,
        404,
        "Nothing found",
        "No matching categories found in the data base."
      )
    end
  end

  def my(conn, _params, user) do
    podcasts_subscribed_ids =
      from(s in Subscription,
        where: s.user_id == ^user.id,
        select: s.podcast_id
      )
      |> Repo.all()

    category_ids =
      from(r in CategoryPodcast,
        join: c in assoc(r, :category),
        where: r.podcast_id in ^podcasts_subscribed_ids,
        group_by: c.id,
        select: c.id,
        order_by: [desc: count(r.category_id)],
        limit: 10
      )
      |> Repo.all()

    categories =
      from(c in Category,
        where: c.id in ^category_ids,
        preload: [:children, :parent]
      )
      |> Repo.all()

    render(conn, "index.json-api", data: categories, opts: [include: "children"])
  end
end
