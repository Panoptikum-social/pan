defmodule Pan.Search.Category do
  alias Pan.Repo
  import Ecto.Query, only: [from: 2]
  alias PanWeb.Category
  require Logger
  alias Pan.Search.Manticore

  def migrate() do
    Manticore.post("mode=raw&query=DROP TABLE categories", "sql")

    "mode=raw&query=CREATE TABLE categories(title text) min_word_len='3' min_infix_len='3'"
    |> Manticore.post("sql")
  end

  def batch_index() do
    Pan.Search.batch_index(
      model: Category,
      preloads: [],
      selects: [:id, :title],
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
    # FIXME
    # category = Repo.get(Category, id)

    # put(
    #   "/panoptikum_" <>
    #     Application.get_env(:pan, :environment) <>
    #     "/categories/" <> Integer.to_string(id),
    #   title: category.title,
    #   url: category_frontend_path(PanWeb.Endpoint, :show, id)
    # )
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
