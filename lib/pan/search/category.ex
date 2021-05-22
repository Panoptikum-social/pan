defmodule Pan.Search.Category do
  alias Pan.Repo
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
end
