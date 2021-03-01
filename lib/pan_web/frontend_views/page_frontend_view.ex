defmodule PanWeb.PageFrontendView do
  use PanWeb, :view

  def list_group_item_cycle(counter) do
    Enum.at(
      [
        "list-group-item-info",
        "list-group-item-danger",
        "list-group-item-warning",
        "list-group-item-primary",
        "list-group-item-success"
      ],
      rem(counter, 5)
    )
  end

  def content_for(url, selector) do
    unsafe_content_for(url, selector)
    |> Phoenix.HTML.raw()
  end

  def unsafe_content_for(url, selector) do
    HTTPoison.get!("https://blog.panoptikum.io/" <> url <> "/", [],
      recv_timeout: 10_000,
      timeout: 10_000,
      hackney: [:insecure],
      ssl: [{:versions, [:"tlsv1.2", :"tlsv1.1", :tlsv1]}]
    ).body
    |> Floki.find(selector)
    |> Floki.raw_html()
  end

  def get_shade(color) do
    color
    |> Atom.to_string()
    |> String.split("-")
    |> List.last()
    |> String.to_integer()
  end
end
