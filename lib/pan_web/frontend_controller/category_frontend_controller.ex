defmodule PanWeb.CategoryFrontendController do
  use PanWeb, :controller
  alias PanWeb.{Category, Podcast}

  def categorized(conn, %{"id" => id}) do
    category =
      Category
      |> Repo.get!(id)
      |> Repo.preload(:parent, podcasts: :categories)

    if category.parent.title == "👩 👨 Community" do
      podcast_ids =
        from(cp in PanWeb.CategoryPodcast,
          where: cp.category_id == ^id,
          select: cp.podcast_id
        )
        |> Repo.all()

      categories =
        from(c in Category,
          join: p in assoc(c, :podcasts),
          where:
            p.id in ^podcast_ids and
              c.id != ^id,
          order_by: c.title,
          group_by: c.id
        )
        |> Repo.all()
        |> Repo.preload(podcasts: from(p in Podcast, where: p.id in ^podcast_ids))
        |> Repo.preload(podcasts: [:categories, [engagements: :persona]])

      render(conn, "categorized.html",
        categories: categories,
        category: category
      )
    else
      render(conn, "no_community.html")
    end
  end
end
