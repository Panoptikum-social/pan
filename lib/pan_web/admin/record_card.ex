defmodule PanWeb.Admin.RecordCard do
  use PanWeb, :live_component
  import PanWeb.CoreComponents

  import PanWeb.Admin.ColumnsFilter
  alias PanWeb.Admin.DataBlock
  alias PanWeb.Admin.RelationsBlock
  alias PanWeb.Admin.Naming
  alias PanWeb.Endpoint
  alias PanWeb.Router.Helpers, as: Routes

  def update(assigns, socket) do
    columns = if assigns.cols == [], do: assigns.slot_columns, else: assigns.cols
    primary_key = assigns.model.__schema__(:primary_key)

    socket =
      assign(socket, assigns)
      |> assign(columns: columns)
      |> assign(primary_key: primary_key)

    {:ok, socket}
  end

  attr :record, :map, required: true
  attr :model, :atom, required: true
  attr :path_helper, :atom, default: nil
  attr :cols, :list, default: []

  slot :slot_columns

  def render(assigns) do
    ~H"""
    <div class="m-2">
      <div class="flex justify-between items-end">
        <span class="flex items-end space-x-2 text-2xl">
          <span class="text-gray-dark">
            Show&nbsp;<span class="font-semibold">{Naming.module_without_namespace(@model)}</span>
          </span>
          <h1 class="max-w-5xl w-full truncate">{Naming.title_from_record(@record)}</h1>
        </span>
        <span>
          <.link navigate={Naming.path %{model: @model,
                                         action: :index,
                                         path_helper: @path_helper}}
                 class="text-link hover:text-link-dark underline">
            {Naming.module_without_namespace(@model)}&nbsp;List
          </.link> &nbsp;
          <.link :if={Map.has_key?(@record, :id)}
                 navigate={Naming.path %{model: @model,
                                         action: :edit,
                                         path_helper: @path_helper,
                                         record: @record}}
                 class="text-link hover:text-link-dark underline">
            Edit {Naming.module_without_namespace(@model)}
          </.link>
          <.link :if={!Map.has_key?(@record, :id)}
                 navigate={Routes.databrowser_path(
                             Endpoint,
                             :edit_mediating,
                             Phoenix.Naming.resource_name(@model),
                             @primary_key |> hd |> Atom.to_string(),
                             Map.get(@record, hd(@primary_key)),
                             @primary_key |> tl |> hd |> Atom.to_string(),
                             Map.get(@record, hd(tl(@primary_key)))
                          )}
                 class="text-link hover:text-link-dark underline">
            Edit {Naming.module_without_namespace(@model)}
          </.link>
        </span>
      </div>

      <div class="flex flex-col md:flex-row space-x-4 items-start mt-4">
        <fieldset class="border border-gray bg-white rounded p-1">
          <legend class="bg-white px-4 border border-gray rounded-lg">Numeric Fields</legend>
          <DataBlock.render columns={number_columns(assigns)}
                            record={@record}
                            model={@model} />
        </fieldset>
        <fieldset class="border border-gray bg-white rounded p-1">
          <legend class="bg-white px-4 border border-gray rounded-lg">Date & Time Fields</legend>
          <DataBlock.render columns={datetime_columns(assigns)}
                            record={@record}
                            model={@model} />
        </fieldset>
        <fieldset class="border border-gray bg-white rounded p-1">
          <legend class="bg-white px-4 border border-gray rounded-lg">Boolean Fields</legend>
          <DataBlock.render columns={boolean_columns(assigns)}
                            record={@record}
                            model={@model} />
        </fieldset>
        <fieldset class="border border-gray bg-white rounded p-1">
          <legend class="bg-white px-4 border border-gray rounded-lg">Relations</legend>
          <RelationsBlock.render record={@record}
                                 model={@model} />
        </fieldset>
      </div>
      <fieldset class="border border-gray bg-white rounded p-1 mt-4">
        <legend class="bg-white px-4 border border-gray rounded-lg">String Fields</legend>
        <DataBlock.render columns={string_columns(assigns)}
                          record={@record}
                          model={@model} />
      </fieldset>
      <fieldset class="border border-gray bg-white rounded p-1 mt-4">
        <legend class="bg-white px-4 border border-gray rounded-lg">Text Fields</legend>
        <DataBlock.render columns={text_columns(assigns)}
                          record={@record}
                          model={@model} />
      </fieldset>
    </div>
    """
  end
end
