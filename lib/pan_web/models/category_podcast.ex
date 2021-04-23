defmodule PanWeb.CategoryPodcast do
  use PanWeb, :model
  alias Pan.Repo

  @primary_key false

  schema "categories_podcasts" do
    belongs_to(:podcast, PanWeb.Podcast, primary_key: true)
    belongs_to(:category, PanWeb.Category, primary_key: true)
  end

  def get_or_insert(category_id, podcast_id) do
    category_podcast =
      Repo.get_by(PanWeb.CategoryPodcast,
        category_id: category_id,
        podcast_id: podcast_id
      )

    case category_podcast do
      nil ->
        %PanWeb.CategoryPodcast{
          category_id: category_id,
          podcast_id: podcast_id
        }
        |> Repo.insert()

      category_podcast ->
        {:ok, category_podcast}
    end
  end
end
