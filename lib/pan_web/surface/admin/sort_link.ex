defmodule PanWeb.Surface.Admin.SortLink do
  use Surface.Component
  alias PanWeb.Surface.Icon

  prop sort_order, :atom
  prop sort_by, :atom
  prop field, :atom
  prop disabled, :boolean
  prop target, :string

  slot default, required: true

  def update(assigns, socket) do
    {:ok, assign(socket, assigns) |> Surface.init()}
  end

  defp toggle_sort_order(:asc), do: :desc
  defp toggle_sort_order(:desc), do: :asc

  def render(assigns) do
    ~H"""
    <a href="#"
      :on-click={{ "sort", target: @target }}
      phx-value-sort-by={{ @field }}
      phx-value-sort-order={{ toggle_sort_order(@sort_order) }}>
      <If condition= {{ @sort_by == @field }}>
        <Icon :if={{ @sort_order == :asc }}
              name="sort-amount-down-alt-solid" />
        <Icon :if={{ @sort_order == :desc }}
              name="sort-amount-down-solid" />
      </If>
      <slot/>
    </a>
    """
  end
end
