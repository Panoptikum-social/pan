defmodule PanWeb.Surface.Admin.RecordCard do
  use Surface.Component
  alias PanWeb.Surface.Admin.{DataBlock, StringBlock}

  prop record, :map, required: true
  slot columns

  def integers(columns) do
    Enum.filter(columns, fn c -> c.type == :integer end)
  end

  def booleans(columns) do
    Enum.filter(columns, fn c -> c.type == :boolean end)
  end

  def dates(columns) do
    Enum.filter(columns, fn c -> c.type in [:datetime, :naive_datetime] end)
  end

  def other(columns) do
    Enum.filter(columns, fn c -> c.type not in [:integer, :boolean, :datetime, :naive_datetime] end)
  end

  def name(struct) do
    struct.__struct__
    |> to_string()
    |> String.split(".")
    |> List.last()
  end

  def render(assigns) do
    ~H"""
    <div class="bg-white">
      <h2 class="text-2xl">
        <span class="text-gray">
          Show <span class="font-semibold">{{ name(@record) }}</span>
        </span> &nbsp; {{ @record.title }}
      </h2>

      <div class="flex space-x-4">
        <DataBlock columns={{ @columns |> integers() }} record={{ @record }} />
        <DataBlock columns={{ @columns |> booleans() }} record={{ @record }} />
        <DataBlock columns={{ @columns |> dates() }} record={{ @record }} />
      </div>
      <StringBlock columns={{ @columns |> other() }} record={{ @record }} />
    </div>
    """
  end
end

defmodule Column do
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
