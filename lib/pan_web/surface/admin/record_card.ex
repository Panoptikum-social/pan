defmodule PanWeb.Surface.Admin.RecordCard do
  use Surface.LiveComponent
  alias PanWeb.Surface.Admin.ShowPresenter

  prop(record, :map, required: true)

  slot(columns)

  def titelize(string) do
    string
    |> String.replace("_", " ")
    |> String.upcase()
  end
end

defmodule Column do
  use Surface.Component, slot: "columns"

  prop(field, :string)
  prop(label, :string)
  prop(sortable, :boolean, default: true)
  prop(searchable, :boolean, default: true)
  prop(presenter, :fun)

  prop(type, :atom,
    values: [:string, :integer, :naive_datetime, :datetime, :boolean, :"Ecto.UUID"],
    default: :string
  )
end
