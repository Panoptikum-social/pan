defmodule PanWeb.Surface.Admin.Column do
  use Surface.Component, slot: "columns"

  prop field, :string
  prop label, :string
  prop sortable, :boolean, default: true
  prop searchable, :boolean, default: true
  prop presenter, :fun

  prop(type, :atom,
       values: [:string, :integer, :naive_datetime, :datetime, :boolean, :"Ecto.UUID"],
       default: :string)
end
