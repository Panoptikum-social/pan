defmodule PanWeb.CategoryController do
  use PanWeb, :controller
  alias Pan.{Repo, Search}
  alias PanWeb.{Category, Podcast}

  plug(:scrub_params, "category" when action in [:create, :update])

  def datatable(conn, _params) do
    categories =
      from(Category, preload: :parent)
      |> Repo.all()

    render(conn, "datatable.json", categories: categories)
  end

  def new(conn, _params) do
    changeset = Category.changeset(%Category{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"category" => category_params}) do
    changeset = Category.changeset(%Category{}, category_params)

    case Repo.insert(changeset) do
      {:ok, _category} ->
        conn
        |> put_flash(:info, "Category created successfully.")
        |> redirect(to: category_path(conn, :index))

      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    category =
      Repo.get!(Category, id)
      |> Repo.preload(:podcasts)
      |> Repo.preload(:parent)
      |> Repo.preload(children: :children)

    render(conn, "show.html", category: category)
  end

  def edit(conn, %{"id" => id}) do
    category = Repo.get!(Category, id)
    changeset = Category.changeset(category)
    render(conn, "edit.html", category: category, changeset: changeset)
  end

  def update(conn, %{"id" => id, "category" => category_params}) do
    id = String.to_integer(id)
    category = Repo.get!(Category, id)
    changeset = Category.changeset(category, category_params)

    case Repo.update(changeset) do
      {:ok, category} ->
        Search.Category.update_index(id)

        conn
        |> put_flash(:info, "Category updated successfully.")
        |> redirect(to: category_path(conn, :show, category))

      {:error, changeset} ->
        render(conn, "edit.html", category: category, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    id = String.to_integer(id)
    category = Repo.get!(Category, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(category)
    Search.Category.delete_index(id)

    conn
    |> put_flash(:info, "Category deleted successfully.")
    |> redirect(to: category_path(conn, :index))
  end

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
