defmodule PanWeb.Api.LanguageView do
  use PanWeb, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "language"

  location(:location)
  attributes([:name, :shortcode, :emoji])

  def location(language, conn) do
    api_language_url(conn, :show, language)
  end
end
