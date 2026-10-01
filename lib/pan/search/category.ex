defmodule Pan.Search.Category do
  alias Pan.Repo
  import Ecto.Query, only: [from: 2]
  alias PanWeb.Category
  require Logger
  alias Pan.Search.Manticore

  def migrate() do
    Manticore.sql("DROP TABLE categories")
    Manticore.sql("CREATE TABLE categories(title text) min_infix_len='2'")
  end

  def selects() do
    [:id, :title]
  end

  def batch_index() do
    Pan.Search.batch_index(
      model: Category,
      preloads: [],
      selects: selects(),
      struct_function: &manticore_struct/1
    )
  end

  # replace, not insert: an insert of an already indexed id fails with
  # "duplicate id", so resetting full_text could never refresh a stale doc
  def manticore_struct(category) do
    %{
      replace: %{
        index: "categories",
        id: category.id,
        doc: %{title: category.title || ""}
      }
    }
  end

  def batch_reset() do
    Logger.info("full_text resetting all categories")
    Repo.update_all(Category, set: [full_text: false])
  end

  def update_index(id) do
    category =
      from(c in Category, where: c.id == ^id, select: ^selects())
      |> Repo.one()

    manticore_struct(category)[:replace]
    |> Jason.encode!()
    |> Manticore.post("replace", "application/json")
  end

  def podcast_ids(category_id) do
    from(cp in "categories_podcasts",
      where: cp.category_id == ^category_id,
      select: cp.podcast_id
    )
    |> Repo.all()
  end

  @doc """
  Podcast and episode docs carry copies of their categories (ids and
  titles, rendered as links in search results), so a category rename or
  merge leaves them stale. Re-flags those podcasts and all their episodes
  for Pan.Job.PushMissingSearchIndex — in a background task, as a big
  category spans millions of episodes.
  """
  def reset_podcasts(podcast_ids) do
    Task.start(fn ->
      from(p in PanWeb.Podcast, where: p.id in ^podcast_ids)
      |> Repo.update_all([set: [full_text: false]], timeout: :infinity)

      from(e in PanWeb.Episode, where: e.podcast_id in ^podcast_ids)
      |> Repo.update_all([set: [full_text: false]], timeout: :infinity)

      Logger.info("Re-flagged #{length(podcast_ids)} podcasts and their episodes for search")
    end)
  end

  def delete_index(id) do
    %{index: "categories", id: id}
    |> Jason.encode!()
    |> Manticore.post("delete", "application/json")
  end

  def delete_index_orphans() do
    Pan.Search.delete_orphans("categories", Category)
  end
end
