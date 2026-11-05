defmodule PanWeb.RecommendationFrontendView do
  use PanWeb, :view

  def title("my_recommendations.html", _assigns),
    do: dgettext("frontend", "My Recommendations") <> " · Panoptikum"

  def title(_, _assigns), do: "🎧 · Panoptikum"
end
