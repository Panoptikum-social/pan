defmodule PanWeb.Surface.Admin.SortLink do
  use Surface.Component
  alias PanWeb.Surface.Icon

  prop(sort_order, :atom, required: true)
  prop(sort_by, :atom, required: true)
  prop(field, :atom, required: true)
  prop(disabled, :boolean, required: false, default: false)
  prop(click, :event, required: true)

  slot(default, required: true)

  defp toggle_sort_order(:asc), do: :desc
  defp toggle_sort_order(:desc), do: :asc

  def render(assigns) do
    ~F"""
    <a href="#"
       :on-click={@click}
       phx-value-sort-by={@field}
       phx-value-sort-order={toggle_sort_order(@sort_order)}>
      {#if @sort_by == @field}
        <Icon :if={@sort_order == :asc}
              name="sort-up-lineawesome-solid" />
        <Icon :if={@sort_order == :desc}
              name="sort-down-lineawesome-solid" />
      {/if}
      <#slot/>
    </a>
    """
  end
end
