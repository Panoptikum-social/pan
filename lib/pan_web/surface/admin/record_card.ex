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
    <div class="bg-white mt-4">
      <h2 class="text-2xl">
        <span class="text-gray">
          Show <span class="italic">{{ name(@record) }}</span>
        </span> &nbsp; {{ @record.title }}
      </h2>

      <div class="flex space-x-4 items-start mt-4">
        <fieldset class="border border-gray bg-gray-lightest rounded p-1">
          <legend class="px-4">Numeric Fields</legend>
          <DataBlock columns={{ number_columns(assigns) }} record={{ @record }} />
        </fieldset>
        <fieldset class="border border-gray bg-gray-lightest rounded p-1">
          <legend class="px-4">Date & Time Fields</legend>
          <DataBlock columns={{ datetime_columns(assigns) }} record={{ @record }} />
        </fieldset>
        <fieldset class="border border-gray bg-gray-lightest rounded p-1">
          <legend class="px-4">Boolean Fields</legend>
          <DataBlock columns={{ boolean_columns(assigns) }} record={{ @record }} />
        </fieldset>
      </div>
      <fieldset class="border border-gray bg-gray-lightest rounded p-1 mt-4">
        <legend class="px-4">String Fields</legend>
        <DataBlock columns={{ string_columns(assigns) }} record={{ @record }} />
      </fieldset>
      <fieldset class="border border-gray bg-gray-lightest rounded p-1 mt-4">
        <legend class="px-4">Text Fields</legend>
        <DataBlock columns={{ text_columns(assigns) }} record={{ @record }} />
      </fieldset>
    </div>
    """
  end
end
