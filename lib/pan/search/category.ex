defmodule Pan.Search.Category do
  alias Pan.Repo
  alias PanWeb.Category
  require Logger

  def batch_index() do
    Pan.Search.batch_index(
      model: Category,
      preloads: [:episodes, :podcasts, :thumbnails],
      selects: [:id, :title]
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
