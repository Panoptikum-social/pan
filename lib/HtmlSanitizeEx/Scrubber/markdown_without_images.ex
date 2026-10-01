defmodule HtmlSanitizeEx.Scrubber.MarkdownWithoutImages do
  @moduledoc """
  HtmlSanitizeEx's MarkdownHTML scrubber without images: user written markdown
  must not make visitors' browsers load anything from third party servers.
  An image is replaced by its alt text.
  """

  use HtmlSanitizeEx, extend: :strip_tags

  def scrub({"img", attributes, _children}) do
    attributes
    |> Enum.find_value("", fn {name, value} -> if name == "alt", do: value end)
  end

  allow_tag_with_uri_attributes("a", ["href"], ["http", "https", "mailto"])
  allow_tag_with_these_attributes("a", ["name", "title"])
  allow_tag_with_this_attribute_values("a", "target", ["_blank"])
  allow_tag_with_this_attribute_values("a", "rel", ["noopener", "noreferrer"])
  allow_tag_with_these_attributes("b", [])
  allow_tag_with_these_attributes("blockquote", [])
  allow_tag_with_these_attributes("br", [])
  allow_tag_with_these_attributes("code", ["class"])
  allow_tag_with_these_attributes("del", [])
  allow_tag_with_these_attributes("em", [])
  allow_tag_with_these_attributes("h1", [])
  allow_tag_with_these_attributes("h2", [])
  allow_tag_with_these_attributes("h3", [])
  allow_tag_with_these_attributes("h4", [])
  allow_tag_with_these_attributes("h5", [])
  allow_tag_with_these_attributes("h6", [])
  allow_tag_with_these_attributes("hr", [])
  allow_tag_with_these_attributes("i", [])
  allow_tag_with_these_attributes("li", [])
  allow_tag_with_these_attributes("ol", ["start"])
  allow_tag_with_these_attributes("p", [])
  allow_tag_with_these_attributes("pre", [])
  allow_tag_with_these_attributes("span", [])
  allow_tag_with_these_attributes("strong", [])
  allow_tag_with_these_attributes("table", [])
  allow_tag_with_these_attributes("tbody", [])
  allow_tag_with_these_attributes("td", ["align"])
  allow_tag_with_these_attributes("th", ["align"])
  allow_tag_with_these_attributes("thead", [])
  allow_tag_with_these_attributes("tr", [])
  allow_tag_with_these_attributes("u", [])
  allow_tag_with_these_attributes("ul", [])
end
