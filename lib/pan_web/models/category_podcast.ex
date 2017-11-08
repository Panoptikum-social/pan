defmodule PanWeb.CategoryPodcast do
  use Pan.Web, :model
  alias Pan.Repo

  @primary_key false

  schema "categories_podcasts" do
    belongs_to :podcast, PanWeb.Podcast
    belongs_to :category, PanWeb.Category
  end


  def get_or_insert(category_id, podcast_id) do
    case Repo.get_by(PanWeb.CategoryPodcast, category_id: category_id,
                                             podcast_id: podcast_id) do
      nil ->
        %PanWeb.CategoryPodcast{category_id: category_id, podcast_id: podcast_id}
        |> Repo.insert()
      category_podcast ->
        {:ok, category_podcast}
    end
  end
end