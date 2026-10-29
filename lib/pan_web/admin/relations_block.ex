defmodule PanWeb.Admin.RelationsBlock do
  use PanWeb, :html
  alias PanWeb.Admin.AssociationLink
  require Integer

  def type(model, association) do
    model.__schema__(:association, association).__struct__
    |> Atom.to_string()
    |> String.split(".")
    |> List.last()
  end

  attr :record, :map, required: true
  attr :model, :atom, required: true

  def render(assigns) do
    ~H"""
    <div
      class="mt-4 grid"
      style="grid-template-columns: max-content 1fr;"
    >
      <%= for {association, index} <- @model.__schema__(:associations) |> Enum.with_index do %>
        <div class={[
          "px-2 py-0.5 text-base-content italic text-right",
          Integer.is_even(index) && "bg-base-100",
          Integer.is_odd(index) && "bg-base-200",
          index > 0 && "border-t-2 border-base-300"
        ]}>
          {type(@model, association)}
        </div>
        <div class={[
          "w-full pl-4 pr-2 py-0.5",
          Integer.is_even(index) && "bg-base-100",
          Integer.is_odd(index) && "bg-base-200",
          index > 0 && "border-t-2 border-base-300"
        ]}>
          <AssociationLink.render
            for={@model.__schema__(:association, association)}
            record={@record}
          />
          <div :if={!@record}>no record</div>
        </div>
      <% end %>
    </div>
    """
  end
end
