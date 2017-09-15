defmodule PanWeb.PageFrontendView do
  use Pan.Web, :view

  def list_group_item_cycle(counter) do
    Enum.at(["list-group-item-info", "list-group-item-danger",
             "list-group-item-warning", "list-group-item-primary", "list-group-item-success"], rem(counter, 5))
  end


  def content_for(url, selector) do
    unsafe_content_for(url, selector)
    |> Phoenix.HTML.raw()
  end

  def unsafe_content_for(url, selector) do
    HTTPoison.get!("https://blog.panoptikum.io/" <> url <> "/").body
    |> Floki.find(selector)
    |> Floki.raw_html()
  end
end