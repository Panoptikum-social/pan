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
    <div class="mt-4">
      <h2 class="text-2xl">
        <span class="text-gray-dark">
          Show <span class="italic">{{ name(@record) }}</span>
        </span> &nbsp; {{ @record.title }}
      </h2>

      <div class="flex space-x-4 items-start mt-4">
        <fieldset class="border border-gray bg-white rounded p-1">
          <legend class="bg-white px-4 border border-gray rounded-lg">Numeric Fields</legend>
          <DataBlock columns={{ number_columns(assigns) }} record={{ @record }} />
        </fieldset>
        <fieldset class="border border-gray bg-white rounded p-1">
          <legend class="bg-white px-4 border border-gray rounded-lg">Date & Time Fields</legend>
          <DataBlock columns={{ datetime_columns(assigns) }} record={{ @record }} />
        </fieldset>
        <fieldset class="border border-gray bg-white rounded p-1">
          <legend class="bg-white px-4 border border-gray rounded-lg">Boolean Fields</legend>
          <DataBlock columns={{ boolean_columns(assigns) }} record={{ @record }} />
        </fieldset>
      </div>
      <fieldset class="border border-gray bg-white rounded p-1 mt-4">
        <legend class="bg-white px-4 border border-gray rounded-lg">String Fields</legend>
        <DataBlock columns={{ string_columns(assigns) }} record={{ @record }} />
      </fieldset>
      <fieldset class="border border-gray bg-white rounded p-1 mt-4">
        <legend class="bg-white px-4 border border-gray rounded-lg">Text Fields</legend>
        <DataBlock columns={{ text_columns(assigns) }} record={{ @record }} />
      </fieldset>
    </div>
    """
  end
end
