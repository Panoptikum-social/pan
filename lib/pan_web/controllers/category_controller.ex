defmodule PanWeb.CategoryController do
  use PanWeb, :controller
  alias Pan.Repo
  alias PanWeb.{Category, Podcast}

  plug(:scrub_params, "category" when action in [:create, :update])

  def get_podcasts(conn, %{"id" => id}) do
    category =
      Repo.get!(Category, id)
      |> Repo.preload(:podcasts)

    podcast_ids = Enum.map(category.podcasts, fn podcast -> podcast.id end)

    podcasts_unassigned = Repo.all(from(p in Podcast, where: p.id not in ^podcast_ids))

    render(conn, "get_podcasts.json",
      podcasts_assigned: category.podcasts,
      podcasts_unassigned: podcasts_unassigned
    )
  end

  def execute_assign(conn, params) do
    category_id = String.to_integer(params["category_id"])

    if params["delete_ids"] do
      delete_ids = Enum.map(params["delete_ids"], fn id -> String.to_integer(id) end)

      from(a in "categories_podcasts",
        where:
          a.category_id == ^category_id and
            a.podcast_id in ^delete_ids
      )
      |> Repo.delete_all()
    end

    if params["add_ids"] do
      add_ids = Enum.map(params["add_ids"], fn id -> String.to_integer(id) end)
      podcasts = Repo.all(from(p in Podcast, where: p.id in ^add_ids))

      category =
        Repo.get(Category, category_id)
        |> Repo.preload(:podcasts)

      Ecto.Changeset.change(category)
      |> Ecto.Changeset.put_assoc(:podcasts, category.podcasts ++ podcasts)
      |> Repo.update!()
    end

    conn
    |> send_resp(200, "")
  end
end
