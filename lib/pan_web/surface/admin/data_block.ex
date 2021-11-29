defmodule PanWeb.Surface.Admin.DataBlock do
  use Surface.Component
  alias PanWeb.Surface.Admin.ShowPresenter
  alias PanWeb.Surface.Admin.Naming
  require Integer

  prop(record, :map, required: true)
  prop(columns, :list, required: true)
  prop(model, :module, required: true)

  def render(assigns) do
    ~F"""
    <div class="mt-4 grid"
         style="grid-template-columns: max-content 1fr;">
      {#for {column, index} <- @columns |> Enum.with_index}
        <div class={"px-2 py-0.5 text-gray-darker italic text-right",
                    "bg-white": Integer.is_even(index),
                    "bg-gray-lightest": Integer.is_odd(index),
                    "border-t-2 border-gray-lighter": index > 0}>
          {Naming.title_from_field(column.field)}
        </div>
        <div class={"w-full pl-4 pr-2 py-0.5",
                    "bg-white": Integer.is_even(index),
                    "bg-gray-lightest": Integer.is_odd(index),
                    "border-t-2 border-gray-lighter": index > 0}>
          <ShowPresenter {=@record}
                         field={column.field}
                         type={column.type}
                         redact={@model.__schema__(:redact_fields) |> Enum.member?(column.field)} />
        </div>
      {/for}
    </div>
    """
  end
end
