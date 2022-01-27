defmodule PanWeb.OpmlFrontendView do
  use PanWeb, :view

  def title("index.html", _assigns), do: "My OPML files · Panoptikum"
  def title("new.html", _assigns), do: "Upload an OPML File · Panoptikum"
  def title(_, _assigns), do: "🎧 · Panoptikum"
end
