defmodule PanWeb.PersonaFrontendView do
  use PanWeb, :view

  def title("email_sent.html", _assigns), do: "Email Sent · Panoptikum"
  def title("grant_access.html", _assigns), do: "Grant Access · Panoptikum"
  def title("not_found.html", _assigns), do: "Persona not Found · Panoptikum"
  def title("warning.html", _assigns), do: "Warning: Claiming a Person · Panoptikum"
  def title(_, _assigns), do: "🎧 · Panoptikum"
end
