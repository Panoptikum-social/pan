defmodule PanWeb.ErrorView do
  use PanWeb, :view

  def render("400.html", assigns) do
    render("not_found.html", assigns)
  end

  def render("404.html", assigns) do
    render("not_found.html", assigns)
  end

  def render("500.html", _assigns) do
    "Server internal error"
  end

  def template_not_found(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
