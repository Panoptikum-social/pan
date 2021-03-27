defmodule PanWeb.Surface.Admin.RecordCard do
  use Surface.Component
  import PanWeb.Surface.Admin.ColumnsFilter
  alias PanWeb.Surface.Admin.DataBlock

  prop(record, :map, required: true)
  slot(columns)

  def name(struct) do
    struct.__struct__
    |> to_string()
    |> String.split(".")
    |> List.last()
  end

  def render(assigns) do
    ~H"""
    <div class="bg-white mt-8">
      <h2 class="text-2xl">
        <span class="text-gray">
          Show <span class="italic">{{ name(@record) }}</span>
        </span> &nbsp; {{ @record.title }}
      </h2>

      <div class="flex space-x-4 items-start mt-4">
        <DataBlock columns={{ number_columns(assigns) }} record={{ @record }} />
        <DataBlock columns={{ datetime_columns(assigns) }} record={{ @record }} />
        <DataBlock columns={{ boolean_columns(assigns) }} record={{ @record }} />
      </div>
      <DataBlock columns={{ string_columns(assigns) }} record={{ @record }} />
      <DataBlock columns={{ text_columns(assigns) }} record={{ @record }} />
    </div>
    """
  end
end
