defmodule Pan.CategoryController do
  use Pan.Web, :controller
  alias Pan.Category
  alias Pan.Podcast
  alias Pan.Follow
  alias Pan.Like
  alias Pan.Repo

  plug :scrub_params, "category" when action in [:create, :update]

  def index(conn, _params) do
    categories = from(category in Category, where: is_nil(category.parent_id),
                                            order_by: :title)
                 |> Repo.all()
                 |> Repo.preload([children: :podcasts])
                 |> Repo.preload(:podcasts)
    render(conn, "index.html", categories: categories, no_children: false)
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
    category = Repo.get!(Category, id)
               |> Repo.preload(podcasts: :owner)
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
    category = Repo.get!(Category, id)
    changeset = Category.changeset(category, category_params)

    case Repo.update(changeset) do
      {:ok, category} ->
        conn
        |> put_flash(:info, "Category updated successfully.")
        |> redirect(to: category_path(conn, :show, category))
      {:error, changeset} ->
        render(conn, "edit.html", category: category, changeset: changeset)
    end
  end


  def delete(conn, %{"id" => id}) do
    category = Repo.get!(Category, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(category)

    conn
    |> put_flash(:info, "Category deleted successfully.")
    |> redirect(to: category_path(conn, :index))
  end


  def merge(conn, _params) do
    categories = Repo.all(from category in Category, where: is_nil(category.parent_id),
                                                     order_by: :title,
                                                     preload: [children: :children])

    render(conn, "merge.html", categories: categories)
  end


  def assign_podcasts(conn, _params) do
    categories = Repo.all(from category in Category, where: is_nil(category.parent_id),
                                                     order_by: :title,
                                                     preload: [children: :children])
    podcasts = Repo.all(Podcast, order_by: :title)

    render(conn, "assign_podcasts.html", categories: categories, podcasts: podcasts)
  end



  def execute_merge(conn, %{"from" => from, "to" => to}) do
    from_id = String.to_integer(from)
    to_id   = String.to_integer(to)

    from(f in Follow, where: f.category_id == ^from_id)
    |> Repo.update_all(set: [category_id: to_id])

    from(l in Like, where: l.category_id == ^from_id)
    |> Repo.update_all(set: [category_id: to_id])

    from(r in "categories_podcasts", where: r.category_id == ^from_id)
    |> Repo.update_all(set: [category_id: to_id])

    from(c in Category, where: c.parent_id == ^from_id)
    |> Repo.update_all(set: [parent_id: to_id])

    Repo.get!(Category, from_id)
    |> Repo.delete!

    categories = Repo.all(from category in Category, where: is_nil(category.parent_id),
                                                     order_by: :title,
                                                     preload: [children: :children])

    render(conn, "merge.html", categories: categories)
  end


  def get_podcasts(conn, %{"id" => id}) do
    category = Repo.get!(Category, id)
               |> Repo.preload(:podcasts)

    podcast_ids = Enum.map(category.podcasts, fn(podcast) -> podcast.id end)

    podcasts_unassigned = Repo.all(from p in Podcast, where: not p.id in ^podcast_ids)

    render conn, "get_podcasts.json", podcasts_assigned: category.podcasts,
                                      podcasts_unassigned: podcasts_unassigned
  end


  def execute_assign(conn, params) do
    category_id = String.to_integer(params["category_id"])

    if params["delete_ids"] do
      delete_ids = Enum.map(params["delete_ids"], fn(id) -> String.to_integer(id) end)

      from(a in "categories_podcasts", where: a.category_id == ^category_id and
                                              a.podcast_id in ^delete_ids)
      |> Repo.delete_all
    end

    if params["add_ids"] do
      add_ids = Enum.map(params["add_ids"], fn(id) -> String.to_integer(id) end)
      podcasts = Repo.all(from p in Podcast, where: p.id in ^add_ids)
      category = Repo.get(Category, category_id)
                 |> Repo.preload(:podcasts)

      Ecto.Changeset.change(category)
      |> Ecto.Changeset.put_assoc(:podcasts, category.podcasts ++ podcasts)
      |> Repo.update!
    end

    conn
    |> send_resp(200, "")
  end
end
