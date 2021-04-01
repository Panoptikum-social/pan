defmodule PanWeb.Surface.Admin.Column do
  use Surface.Component, slot: "columns"

  prop(field, :string, required: true)
  prop(label, :string, required: true)
  prop(sortable, :boolean, required: false, default: true)
  prop(searchable, :boolean, required: false, default: true)
  prop(presenter, :fun, required: false)

  prop(type, :atom,
    required: false,
    values: [:string, :integer, :naive_datetime, :datetime, :boolean, :"Ecto.UUID"],
    default: :string
  )
end
