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

  # Used by the shared _head.html for the browser tab: "404 Not Found · Panoptikum".
  # _head.html passes @conn.assigns (no status in there), so the status comes
  # from the template name ("404.html").
  def title(template, _conn_assigns) do
    status = template |> String.split(".") |> hd()
    "#{status} #{Phoenix.Controller.status_message_from_template(template)} · Panoptikum"
  end

  def template_not_found(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
