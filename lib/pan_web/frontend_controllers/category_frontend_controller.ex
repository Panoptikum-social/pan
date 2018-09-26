defmodule PanWeb.CategoryFrontendController do
  use Pan.Web, :controller
  alias PanWeb.{Category, Episode, Language, Podcast}

  def index(conn, _params) do
    categories = from(c in Category, order_by: :title,
                                     where: is_nil(c.parent_id))
                 |> Repo.all()
                 |> Repo.preload(children: from(cat in Category, order_by: cat.title))

    render(conn, "index.html", categories: categories)
  end


  def show(conn, %{"id" => id}) do
    if category = Repo.get(Category, id) do
      category = category
                 |> Repo.preload([children: from(c in Category, order_by: c.title)])
                 |> Repo.preload(:parent)

      podcasts = from(l in Language, right_join: p in assoc(l, :podcasts),
                                     join: c in assoc(p, :categories),
                                     where: c.id == ^id,
                                     select: %{id: p.id,
                                               title: p.title,
                                               language_name: l.name,
                                               language_emoji: l.emoji})
                                     |> Repo.all()

      render(conn, "show.html", category: category,
                                podcasts: podcasts)
    else
      conn
      |> put_status(:not_found)
      |> render("not_found.html")
    end
  end


  def stats(conn, _params) do
    categories = from(c in Category, order_by: :title,
                                     where: is_nil(c.parent_id))
                 |> Repo.all()
                 |> Repo.preload(children: from(cat in Category, order_by: cat.title))
                 |> Repo.preload([:podcasts, children: :podcasts])

    render(conn, "stats.html", categories: categories)
  end


  def show_stats(conn, %{"id" => id}) do
    category = Category
               |> Repo.get!(id)
               |> Repo.preload([children: from(c in Category, order_by: c.title)])
               |> Repo.preload(:parent)

    podcasts = from(l in Language, right_join: p in assoc(l, :podcasts),
                                   join: c in assoc(p, :categories),
                                   where: c.id == ^id,
                                   select: %{id: p.id,
                                             title: p.title,
                                             language_name: l.name,
                                             language_emoji: l.emoji})
                                   |> Repo.all()

    render(conn, "show_stats.html", category: category,
                              podcasts: podcasts)
  end


  def latest_episodes(conn, %{"id" => id} = params) do
    category = Category
               |> Repo.get!(id)
               |> Repo.preload(:parent)

    if category.parent.title == "👩 👨 Community" do
      podcast_ids = from(c in Category, join: p in assoc(c, :podcasts),
                                        where: is_false(p.blocked) and
                                               c.id == ^id,
                                        select: p.id)
                    |> Repo.all

      latest_episodes =
        from(e in Episode, order_by: [desc: :publishing_date],
                           where: e.publishing_date < ^NaiveDateTime.utc_now() and
                                  e.podcast_id in ^podcast_ids,
                           preload: :podcast)
        |> Repo.paginate(params)

      render(conn, "latest_episodes.html", latest_episodes: latest_episodes,
                                           category_id: category.id,
                                           category_title: category.title)
    else
      render(conn, "no_community.html")
    end
  end


  def categorized(conn, %{"id" => id}) do
    category = Category
               |> Repo.get!(id)
               |> Repo.preload(:parent, [podcasts: :categories])

    if category.parent.title == "👩 👨 Community" do
      podcast_ids = from(cp in PanWeb.CategoryPodcast, where: cp.category_id == ^id,
                                                       select: cp.podcast_id)
                    |> Repo.all()

      categories = from(c in Category, join: p in assoc(c, :podcasts),
                                       where: p.id in ^podcast_ids and
                                              c.id != ^id,
                                       order_by: c.title,
                                       group_by: c.id)
                   |> Repo.all()
                   |> Repo.preload(podcasts: from(p in Podcast, where: p.id in ^podcast_ids))
                   |> Repo.preload(podcasts: [:categories, [engagements: :persona]])


      render(conn, "categorized.html", categories: categories,
                                       category: category)
    else
      render(conn, "no_community.html")
    end
  end
end
