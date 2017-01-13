defmodule Pan.CategoryPodcast do
  use Pan.Web, :model

  @primary_key false

  schema "categories_podcasts" do
    belongs_to :podcast, Pan.Podcast
    belongs_to :category, Pan.Category
  end
end