defmodule PanWeb.PageFrontendView do
  use PanWeb, :view

  def title("done.html", _assigns), do: "Task Done · Panoptikum"
  def title("error.html", _assigns), do: "Error Occurred · Panoptikum"
  def title("pro_features.html", _assigns), do: "Pro Features · Panoptikum"
  def title("started.html", _assigns), do: "Task Started · Panoptikum"
  def title(_, _assigns), do: "🎧 · Panoptikum"

  def content_for(url, selector) do
    unsafe_content_for(url, selector)
    |> Phoenix.HTML.raw()
  end

  def unsafe_content_for(url, selector) do
    HTTPoison.get!("https://blog.panoptikum.social/" <> url <> "/", [],
      recv_timeout: 10_000,
      timeout: 10_000,
      hackney: [:insecure],
      ssl: [{:versions, [:"tlsv1.2", :"tlsv1.1", :tlsv1]}]
    ).body
    |> Floki.find(selector)
    |> Floki.raw_html()
  end
end
