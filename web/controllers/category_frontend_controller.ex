defmodule Pan.CategoryFrontendController do
  use Pan.Web, :controller

  alias Pan.Category
  alias Pan.Language

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
end
