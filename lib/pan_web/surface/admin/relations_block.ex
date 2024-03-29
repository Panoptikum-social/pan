defmodule PanWeb.Surface.Admin.RelationsBlock do
  use Surface.Component
  alias PanWeb.Surface.Admin.AssociationLink
  require Integer

  prop(record, :map, required: true)
  prop(model, :module, required: true)

  def type(model, association) do
    model.__schema__(:association, association).__struct__
    |> Atom.to_string()
    |> String.split(".")
    |> List.last()
  end

  def render(assigns) do
    ~F"""
    <div class="mt-4 grid"
         style="grid-template-columns: max-content 1fr;">
      {#for {association, index} <- @model.__schema__(:associations) |> Enum.with_index}
        <div class={"px-2 py-0.5 text-gray-darker italic text-right",
                    "bg-white": Integer.is_even(index),
                    "bg-gray-lightest": Integer.is_odd(index),
                    "border-t-2 border-gray-lighter": index > 0}>
          {type(@model, association)}
        </div>
        <div class={"w-full pl-4 pr-2 py-0.5",
                    "bg-white": Integer.is_even(index),
                    "bg-gray-lightest": Integer.is_odd(index),
                    "border-t-2 border-gray-lighter": index > 0}>
          <AssociationLink for={@model.__schema__(:association, association)}
                           {=@record} />
          <div :if={!@record}>no record</div>
        </div>
      {/for}
    </div>
    """
  end
end
