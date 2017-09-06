defmodule PanWeb.CategoryPodcast do
  use Pan.Web, :model

  @primary_key false

  schema "categories_podcasts" do
    belongs_to :podcast, PanWeb.Podcast
    belongs_to :category, PanWeb.Category
  end
end