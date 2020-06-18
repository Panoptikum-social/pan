defmodule PanWeb.LanguageView do
  use Pan.Web, :view

  def render("datatable.json", %{languages: languages}) do
    %{languages: Enum.map(languages, &language_json/1)}
  end

  def language_json(language) do
    %{
      id: language.id,
      shortcode: language.shortcode,
      name: language.name,
      emoji: language.emoji,
      actions: datatable_actions(language, &language_path/3)
    }
  end
end
