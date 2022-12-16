defmodule PanWeb.Surface.Admin.SortLink do
  use Surface.Component
  alias PanWeb.Surface.Icon

  prop(sort_order, :atom, required: true)
  prop(sort_by, :atom, required: true)
  prop(field, :atom, required: true)
  prop(disabled, :boolean, required: false, default: false)
  prop(click, :event, required: true)

  slot(default, required: true)

  defp cycle_sort_order(:asc_nulls_last), do: :asc_nulls_first
  defp cycle_sort_order(:asc_nulls_first), do: :desc_nulls_last
  defp cycle_sort_order(:asc), do: :desc_nulls_last
  defp cycle_sort_order(:desc_nulls_last), do: :desc_nulls_first
  defp cycle_sort_order(:desc_nulls_first), do: :asc_nulls_last
  defp cycle_sort_order(:desc), do: :asc_nulls_last

  def render(assigns) do
    ~F"""
    <a href="#"
       :on-click={@click}
       phx-value-sort-by={@field}
       phx-value-sort-order={cycle_sort_order(@sort_order)}>
      {#if @sort_by == @field}
        {#if @sort_order |> Atom.to_string() |> String.ends_with?("last")}
          0 last
        {#else}
          0 first
        {/if}
        <Icon :if={@sort_order |> Atom.to_string() |> String.starts_with?("asc")}
              name="sort-up-lineawesome-solid" />
        <Icon :if={@sort_order |> Atom.to_string() |> String.starts_with?("desc")}
              name="sort-down-lineawesome-solid" />
      {/if}
      <#slot/>
    </a>
    """
  end
end
