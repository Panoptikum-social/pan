defmodule PanWeb.Api.LanguageView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "language"

  location :location
  attributes [:name, :shortcode, :emoji]

  def location(language, conn) do
    language_url(conn, :show, language)
  end
end
