defmodule PanWeb.CategoryFrontendView do
  use PanWeb, :view

  def title("categorized.html", _assigns),
    do: dgettext("frontend", "Podcasts Categorized") <> " · Panoptikum"

  def title("no_community.html", _assigns),
    do: dgettext("frontend", "No Community") <> " · Panoptikum"

  def title(_, _assigns), do: "🎧 · Panoptikum"
end
