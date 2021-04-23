defmodule PanWeb.LanguagePodcast do
  use PanWeb, :model

  @primary_key false

  schema "languages_podcasts" do
    belongs_to(:podcast, PanWeb.Podcast, primary_key: true)
    belongs_to(:language, PanWeb.Language, primary_key: true)
  end
end
