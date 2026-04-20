defmodule PanWeb.Surface.Admin.SortLink do
  use PanWeb, :html
  import PanWeb.ViewHelpers, only: [icon: 2]

  attr :sort_order, :atom, required: true
  attr :sort_by, :atom, required: true
  attr :field, :atom, required: true
  attr :disabled, :boolean, default: false
  attr :click, :string, required: true
  attr :target, :any, default: nil

  slot :inner_block, required: true

  defp cycle_sort_order(:asc_nulls_last), do: :asc_nulls_first
  defp cycle_sort_order(:asc_nulls_first), do: :desc_nulls_last
  defp cycle_sort_order(:asc), do: :desc_nulls_last
  defp cycle_sort_order(:desc_nulls_last), do: :desc_nulls_first
  defp cycle_sort_order(:desc_nulls_first), do: :asc_nulls_last
  defp cycle_sort_order(:desc), do: :asc_nulls_last

  def render(assigns) do
    ~H"""
    <a href="#"
       phx-click={@click}
       phx-target={@target}
       phx-value-sort-by={@field}
       phx-value-sort-order={cycle_sort_order(@sort_order)}>
      <%= if @sort_by == @field do %>
        <%= if @sort_order |> Atom.to_string() |> String.ends_with?("last") do %>
          0 last
        <% else %>
          0 first
        <% end %>
        <%= if @sort_order |> Atom.to_string() |> String.starts_with?("asc") do %>
          {icon("sort-up-lineawesome-solid", class: "h-5 w-5 inline align-text-bottom")}
        <% end %>
        <%= if @sort_order |> Atom.to_string() |> String.starts_with?("desc") do %>
          {icon("sort-down-lineawesome-solid", class: "h-5 w-5 inline align-text-bottom")}
        <% end %>
      <% end %>
      {render_slot(@inner_block)}
    </a>
    """
  end
end
