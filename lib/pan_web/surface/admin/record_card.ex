defmodule PanWeb.Surface.Admin.RecordCard do
  use Surface.Component
  alias PanWeb.Router.Helpers, as: Routes
  import PanWeb.Surface.Admin.ColumnsFilter
  alias PanWeb.Surface.Admin.DataBlock
  alias Surface.Components.LiveRedirect

  prop(record, :map, required: true)
  prop(resource, :module, required: true)
  prop(path_helper, :atom, required: true)
  slot(columns)

  def module_name(resource) do
    resource
    |> to_string()
    |> String.split(".")
    |> List.last()
  end

  def render(assigns) do
    ~H"""
    <div class="mt-2">
      <div class="flex justify-between items-end">
        <span class="flex items-end space-x-2 text-2xl">
          <span class="text-gray-dark">
            Show <span class="font-semibold">{{ module_name(@resource) }}</span>
          </span>
          <h2>{{ @record.title }}</h2>
        </span>
        <span>
           <LiveRedirect to={{ Function.capture(Routes, @path_helper, 2).(@socket, :index) }}
                         class="text-link hover:text-link-dark underline">
             {{ module_name(@resource) }} List
          </LiveRedirect> &nbsp;
          <LiveRedirect to={{ Function.capture(Routes, @path_helper, 3).(@socket, :edit, @record) }}
                        class="text-link hover:text-link-dark underline">
            Edit {{ module_name(@resource) }}
          </LiveRedirect>
        </span>
      </div>

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
