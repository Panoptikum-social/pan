defmodule Pan.LanguageApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "language"

  location :language_api_url
  attributes [:name, :shortcode, :emoji]

  def language_api_url(language, conn) do
    language_api_url(conn, :show, language)
  end
end
