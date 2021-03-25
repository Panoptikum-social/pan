defmodule PanWeb.Surface.Admin.RecordCard do
  use Surface.Component
  import PanWeb.Surface.Admin.ColumnsFilter
  alias PanWeb.Surface.Admin.{DataBlock, StringBlock}

  prop record, :map, required: true
  slot columns

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
        <DataBlock columns={{ assigns |> number_columns() }} record={{ @record }} />
        <DataBlock columns={{ assigns |> boolean_columns() }} record={{ @record }} />
        <DataBlock columns={{ assigns |> datetime_columns() }} record={{ @record }} />
      </div>
      <StringBlock columns={{ assigns |> string_columns() }} record={{ @record }} />
    </div>
    """
  end
end
