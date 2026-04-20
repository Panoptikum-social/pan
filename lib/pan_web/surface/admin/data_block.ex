defmodule PanWeb.Surface.Admin.DataBlock do
  use PanWeb, :html
  alias PanWeb.Admin.ShowPresenter
  alias PanWeb.Admin.Naming
  require Integer

  attr :record, :map, required: true
  attr :columns, :list, required: true
  attr :model, :atom, required: true

  def render(assigns) do
    ~H"""
    <div class="mt-4 grid"
         style="grid-template-columns: max-content 1fr;">
      <%= for {column, index} <- Enum.with_index(@columns) do %>
        <div class={[
          "px-2 py-0.5 text-gray-darker italic text-right",
          Integer.is_even(index) && "bg-white",
          Integer.is_odd(index) && "bg-gray-lightest",
          index > 0 && "border-t-2 border-gray-lighter"
        ]}>
          {Naming.title_from_field(column.field)}
        </div>
        <div class={[
          "w-full pl-4 pr-2 py-0.5",
          Integer.is_even(index) && "bg-white",
          Integer.is_odd(index) && "bg-gray-lightest",
          index > 0 && "border-t-2 border-gray-lighter"
        ]}>
          <ShowPresenter.render record={@record}
                                field={column.field}
                                type={column.type}
                                redact={@model.__schema__(:redact_fields) |> Enum.member?(column.field)} />
        </div>
      <% end %>
    </div>
    """
  end
end
