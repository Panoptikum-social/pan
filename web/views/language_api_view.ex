defmodule Pan.LanguageApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "language"

  location "https://panoptikum.io/jsonapi/languages/:id"
  attributes [:name, :shortcode, :emoji]
end
