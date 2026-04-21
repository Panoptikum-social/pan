defmodule PanWeb.Component.Moderation.NumberField do
  use PanWeb, :html

  attr :name, :string, required: true
  attr :redact, :boolean, required: false, default: false

  def render(assigns) do
    ~H"""
    <%= if @redact do %>
      <.input value="** redacted **" readonly />
    <% else %>
      <.input
        type="number"
        name={@name}
        readonly={@name |> Atom.to_string() |> String.ends_with?("id")}
        class={"#{if @name |> Atom.to_string() |> String.ends_with?("id"), do: "cursor-not-allowed" } w-full input"}
      />
    <% end %>
    """
  end
end
