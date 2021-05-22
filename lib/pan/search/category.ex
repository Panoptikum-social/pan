defmodule Pan.Search.Category do
  alias Pan.Repo
  alias PanWeb.Category
  require Logger
  alias Pan.Search.Manticore
  alias HTTPoison.Response

  def migrate() do
    data = "mode=raw&query=CREATE TABLE categories(title text) " <>
           "min_word_len='3' " <>
           "min_infix_len='3' "

    {:ok, %Response{status_code: response_code, body: response_body}} =
      Manticore.post(endpoint: "sql", data: data)

    IO.inspect response_code
    IO.inspect response_body
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
