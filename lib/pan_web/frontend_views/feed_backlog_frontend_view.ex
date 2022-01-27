defmodule PanWeb.FeedBacklogFrontendView do
  use PanWeb, :view

  def title("new.html", _assigns), do: "Suggest a Podcast · Panoptikum"
  def title(_, _assigns), do: "🎧 · Panoptikum"
end
