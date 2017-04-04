defmodule Pan.ErrorView do
  use Pan.Web, :view

  def render("404.html", assigns) do
    render "not_found.html", assigns
  end

  def render("500.html", _assigns) do
    "Server internal error"
  end

  # In case no render clause matches or no
  # template is found, let's render it as 500
  def template_not_found(_template, assigns) do
    render "500.html", assigns
  end
end
