defmodule PanWeb.ModerationFrontendView do
  use PanWeb, :view

  def title("my_moderations.html", _assigns),
    do: dgettext("moderation", "My Moderations") <> " · Panoptikum"

  def title(_, _assigns), do: "🎧 · Panoptikum"
end
