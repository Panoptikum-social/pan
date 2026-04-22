defmodule PanWeb.Component.Moderation.NumberField do
  use PanWeb, :html

  attr :name, :string, required: true
  attr :value, :any, default: nil
  attr :redact, :boolean, required: false, default: false

  def render(assigns) do
    ~H"""
    <%= if @redact do %>
      <.input label={Phoenix.Naming.humanize(@name)} value="** redacted **" readonly />
    <% else %>
      <.input
        type="number"
        label={Phoenix.Naming.humanize(@name)}
        name={@name}
        value={@value}
        readonly={@name |> Atom.to_string() |> String.ends_with?("id")}
        class={"#{if @name |> Atom.to_string() |> String.ends_with?("id"), do: "cursor-not-allowed" } w-full input input-sm"}
      />
    <% end %>
    """
  end
end
