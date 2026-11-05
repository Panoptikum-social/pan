defmodule PanWeb.FeedBacklogFrontendView do
  use PanWeb, :view

  def title("new.html", _assigns),
    do: dgettext("frontend", "Suggest a Podcast") <> " · Panoptikum"

  def title(_, _assigns), do: "🎧 · Panoptikum"
end
