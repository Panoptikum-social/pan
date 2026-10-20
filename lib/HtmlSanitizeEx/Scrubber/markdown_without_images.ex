defmodule HtmlSanitizeEx.Scrubber.MarkdownWithoutImages do
  @moduledoc """
  HtmlSanitizeEx's MarkdownHTML scrubber without images: user written markdown
  must not make visitors' browsers load anything from third party servers.
  An image is replaced by its alt text. `data-sourcepos` (the source lines
  and columns an element comes from) is kept for the pad preview.
  """

  use HtmlSanitizeEx, extend: :strip_tags

  def scrub({"img", attributes, _children}) do
    attributes
    |> Enum.find_value("", fn {name, value} -> if name == "alt", do: value end)
  end

  allow_tag_with_uri_attributes("a", ["href"], ["http", "https", "mailto"])
  allow_tag_with_these_attributes("a", ["name", "title", "data-sourcepos"])
  allow_tag_with_this_attribute_values("a", "target", ["_blank"])
  allow_tag_with_this_attribute_values("a", "rel", ["noopener", "noreferrer"])
  allow_tag_with_these_attributes("b", ["data-sourcepos"])
  allow_tag_with_these_attributes("blockquote", ["data-sourcepos"])
  allow_tag_with_these_attributes("br", ["data-sourcepos"])
  allow_tag_with_these_attributes("code", ["class", "data-sourcepos"])
  allow_tag_with_these_attributes("del", ["data-sourcepos"])
  allow_tag_with_these_attributes("em", ["data-sourcepos"])
  allow_tag_with_these_attributes("h1", ["data-sourcepos"])
  allow_tag_with_these_attributes("h2", ["data-sourcepos"])
  allow_tag_with_these_attributes("h3", ["data-sourcepos"])
  allow_tag_with_these_attributes("h4", ["data-sourcepos"])
  allow_tag_with_these_attributes("h5", ["data-sourcepos"])
  allow_tag_with_these_attributes("h6", ["data-sourcepos"])
  allow_tag_with_these_attributes("hr", ["data-sourcepos"])
  allow_tag_with_these_attributes("i", ["data-sourcepos"])
  allow_tag_with_these_attributes("li", ["data-sourcepos"])
  allow_tag_with_these_attributes("ol", ["start", "data-sourcepos"])
  allow_tag_with_these_attributes("p", ["data-sourcepos"])
  allow_tag_with_these_attributes("pre", ["data-sourcepos"])
  allow_tag_with_these_attributes("span", ["data-sourcepos"])
  allow_tag_with_these_attributes("strong", ["data-sourcepos"])
  allow_tag_with_these_attributes("table", ["data-sourcepos"])
  allow_tag_with_these_attributes("tbody", ["data-sourcepos"])
  allow_tag_with_these_attributes("td", ["align", "data-sourcepos"])
  allow_tag_with_these_attributes("th", ["align", "data-sourcepos"])
  allow_tag_with_these_attributes("thead", ["data-sourcepos"])
  allow_tag_with_these_attributes("tr", ["data-sourcepos"])
  allow_tag_with_these_attributes("u", ["data-sourcepos"])
  allow_tag_with_these_attributes("ul", ["data-sourcepos"])
end
