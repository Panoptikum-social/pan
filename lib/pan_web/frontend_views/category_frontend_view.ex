defmodule PanWeb.CategoryFrontendView do
  use PanWeb, :view

  def title("categorized.html", _assigns), do: "Podcasts Categorized · Panoptikum"
  def title("no_community.html", _assigns), do: "No Community · Panoptikum"
  def title(_, _assigns), do: "🎧 · Panoptikum"
end
