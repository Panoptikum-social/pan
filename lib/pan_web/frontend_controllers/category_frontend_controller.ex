defmodule PanWeb.CategoryFrontendController do
  use Pan.Web, :controller

  alias PanWeb.Category
  alias PanWeb.Language

  def index(conn, _params) do
    categories = from(c in Category, order_by: :title,
                                     where: is_nil(c.parent_id))
                 |> Repo.all()
                 |> Repo.preload(children: from(cat in Category, order_by: cat.title))

    render(conn, "index.html", categories: categories)
  end


  def show(conn, %{"id" => id}) do
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

    render(conn, "show.html", category: category,
                              podcasts: podcasts)
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

    unless category.parent.title == "👩 👨 Community" do
      render(conn, "no_community.html")
    else
      latest_episodes =
        from(e in PanWeb.Episode, order_by: [desc: :publishing_date],
                                  join: p in assoc(e, :podcast),
                                  join: c in assoc(p, :categories),
                                  where: (is_nil(p.blocked) or p.blocked == false) and
                                         (e.publishing_date < ^NaiveDateTime.utc_now()) and
                                         (c.id == ^id),
                                  preload: :podcast)
        |> Repo.paginate(params)

      render(conn, "latest_episodes.html", latest_episodes: latest_episodes,
                                           category_id: category.id,
                                           category_title: category.title)
    end
  end
end
