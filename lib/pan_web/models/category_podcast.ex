defmodule PanWeb.CategoryPodcast do
  use PanWeb, :model
  alias Pan.Repo

  @primary_key false

  schema "categories_podcasts" do
    belongs_to(:podcast, PanWeb.Podcast, primary_key: true)
    belongs_to(:category, PanWeb.Category, primary_key: true)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:podcast_id, :category_id])
    |> validate_required([:podcast_id, :category_id])
  end

  def get_or_insert(category_id, podcast_id) do
    category_podcast =
      Repo.get_by(PanWeb.CategoryPodcast,
        category_id: category_id,
        podcast_id: podcast_id
      )

    case category_podcast do
      nil ->
        result =
          %PanWeb.CategoryPodcast{
            category_id: category_id,
            podcast_id: podcast_id
          }
          |> Repo.insert()

        # podcast and episode docs carry the podcast's categories
        Pan.Search.Category.reset_podcasts([podcast_id])
        result

      category_podcast ->
        {:ok, category_podcast}
    end
  end

  def delete(category_id, podcast_id) do
    result =
      from(cp in PanWeb.CategoryPodcast,
        where: cp.category_id == ^category_id and cp.podcast_id == ^podcast_id
      )
      |> Repo.delete_all()

    # podcast and episode docs carry the podcast's categories
    Pan.Search.Category.reset_podcasts([podcast_id])
    result
  end
end
