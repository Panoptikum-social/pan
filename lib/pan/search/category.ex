defmodule Pan.Search.Category do
  alias Pan.Repo
  import Ecto.Query, only: [from: 2]
  alias PanWeb.Category
  require Logger
  alias Pan.Search.Manticore

  def migrate() do
    Manticore.post("mode=raw&query=DROP TABLE categories", "sql")

    "mode=raw&query=CREATE TABLE categories(title text) min_infix_len='2'"
    |> Manticore.post("sql")
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

  def manticore_struct(category) do
    %{
      insert: %{
        index: "categories",
        id: category.id,
        doc: %{title: category.title || ""}
      }
    }
  end

  def batch_reset() do
    Logger.info("=== full_text resetting all categories ===")
    Repo.update_all(Category, set: [full_text: false])
  end

  def update_index(id) do
    category =
      from(c in Category, where: c.id == ^id, select: ^selects())
      |> Repo.one()

    manticore_struct(category)[:insert]
    |> Jason.encode!()
    |> Manticore.post("replace")
  end

  def delete_index(id) do
    %{index: "categories", id: id}
    |> Jason.encode!()
    |> Manticore.post("delete")
  end

  def delete_index_orphans() do
    category_ids =
      from(c in Category, select: c.id)
      |> Repo.all()

    max_category_id = Enum.max(category_ids)

    all_ids =
      Range.new(1, max_category_id)
      |> Enum.to_list()

    deleted_ids = all_ids -- category_ids

    for deleted_id <- deleted_ids, do: delete_index(deleted_id)
  end
end
