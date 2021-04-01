defmodule PanWeb.Surface.Admin.RecordCard do
  use Surface.LiveComponent
  import PanWeb.Surface.Admin.ColumnsFilter
  alias PanWeb.Surface.Admin.DataBlock
  alias Surface.Components.LiveRedirect
  alias PanWeb.Surface.Admin.Naming

  prop(record, :map, required: true)
  prop(model, :module, required: true)
  prop(path_helper, :atom, required: false)
  prop(cols, :list, required: false, default: [])

  data(columns, :list, default: [])
  slot(slot_columns)

  def update(assigns, socket) do
    columns = if assigns.cols == [], do: assigns.slot_columns, else: assigns.cols
    resource = Phoenix.Naming.resource_name(assigns.model)

    socket =
      assign(socket, assigns)
      |> assign(columns: columns)
    {:ok, socket}
  end

  def module_name(model) do
    model
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
            Show <span class="font-semibold">{{ module_name(@model) }}</span>
          </span>
          <h2>{{ @record.title }}</h2>
        </span>
        <span>
           <LiveRedirect to={{ Naming.path %{socket: @socket,
                                             model: @model,
                                             method: :index,
                                             path_helper: @path_helper} }}
                         class="text-link hover:text-link-dark underline">
             {{ module_name(@model) }} List
          </LiveRedirect> &nbsp;
          <LiveRedirect to={{ Naming.path %{socket: @socket,
                                            model: @model,
                                            method: :edit,
                                            path_helper: @path_helper,
                                            record: @record} }}
                        class="text-link hover:text-link-dark underline">
            Edit {{ module_name(@model) }}
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
