defmodule PanWeb.LanguagePodcast do
  use Pan.Web, :model

  @primary_key false

  schema "languages_podcasts" do
    belongs_to(:podcast, PanWeb.Podcast)
    belongs_to(:language, PanWeb.Language)
  end
end
