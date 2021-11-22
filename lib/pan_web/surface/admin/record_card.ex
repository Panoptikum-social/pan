defmodule PanWeb.Surface.Admin.RecordCard do
  use Surface.LiveComponent
  import PanWeb.Surface.Admin.ColumnsFilter
  alias PanWeb.Surface.Admin.DataBlock
  alias PanWeb.Surface.Admin.RelationsBlock
  alias Surface.Components.LiveRedirect
  alias PanWeb.Surface.Admin.Naming
  alias PanWeb.Endpoint
  alias PanWeb.Router.Helpers, as: Routes

  prop(record, :map, required: true)
  prop(model, :module, required: true)
  prop(path_helper, :atom, required: false)
  prop(cols, :list, required: false, default: [])

  data(columns, :list, default: [])
  data(primary_key, :list, default: [])
  slot(slot_columns)

  def update(assigns, socket) do
    columns = if assigns.cols == [], do: assigns.slot_columns, else: assigns.cols
    primary_key = assigns.model.__schema__(:primary_key)

    socket =
      assign(socket, assigns)
      |> assign(columns: columns)
      |> assign(primary_key: primary_key)
    {:ok, socket}
  end

  def render(assigns) do
    ~F"""
    <div class="m-2">
      <div class="flex justify-between items-end">
        <span class="flex items-end space-x-2 text-2xl">
          <span class="text-gray-dark">
            Show&nbsp;<span class="font-semibold">{Naming.module_without_namespace(@model)}</span>
          </span>
          <h2 class="max-w-screen-lg w-full truncate">{Naming.title_from_record(@record)}</h2>
        </span>
        <span>
           <LiveRedirect to={Naming.path %{
                                             model: @model,
                                             method: :index,
                                             path_helper: @path_helper}}
                         class="text-link hover:text-link-dark underline">
             {Naming.module_without_namespace(@model)}&nbsp;List
          </LiveRedirect> &nbsp;
          <LiveRedirect :if={Map.has_key?(@record, :id)}
                        to={Naming.path %{  model: @model,
                                            method: :edit,
                                            path_helper: @path_helper,
                                            record: @record}}
                        class="text-link hover:text-link-dark underline">
            Edit {Naming.module_without_namespace(@model)}
          </LiveRedirect>

          <LiveRedirect :if={!Map.has_key?(@record, :id)}
                        to={Routes.databrowser_path(
                          Endpoint,
                          :edit_mediating,
                          Phoenix.Naming.resource_name(@model),
                          hd(@primary_key) |> Atom.to_string,
                          Map.get(@record, hd(@primary_key)),
                          hd(tl(@primary_key)) |> Atom.to_string,
                          Map.get(@record, hd(tl(@primary_key)))
                        )}
                        class="text-link hover:text-link-dark underline">
            Edit {Naming.module_without_namespace(@model)}
          </LiveRedirect>
        </span>
      </div>

      <div class="flex flex-col md:flex-row space-x-4 items-start mt-4">
        <fieldset class="border border-gray bg-white rounded p-1">
          <legend class="bg-white px-4 border border-gray rounded-lg">Numeric Fields</legend>
          <DataBlock columns={number_columns(assigns)}
                     record={@record}
                     model={@model} />
        </fieldset>
        <fieldset class="border border-gray bg-white rounded p-1">
          <legend class="bg-white px-4 border border-gray rounded-lg">Date & Time Fields</legend>
          <DataBlock columns={datetime_columns(assigns)}
                     record={@record}
                     model={@model} />
        </fieldset>
        <fieldset class="border border-gray bg-white rounded p-1">
          <legend class="bg-white px-4 border border-gray rounded-lg">Boolean Fields</legend>
          <DataBlock columns={boolean_columns(assigns)}
                     record={@record}
                     model={@model} />
        </fieldset>
        <fieldset class="border border-gray bg-white rounded p-1">
          <legend class="bg-white px-4 border border-gray rounded-lg">Relations</legend>
          <RelationsBlock record={@record}
                          model={@model} />
        </fieldset>
      </div>
      <fieldset class="border border-gray bg-white rounded p-1 mt-4">
        <legend class="bg-white px-4 border border-gray rounded-lg">String Fields</legend>
        <DataBlock columns={string_columns(assigns)}
                   record={@record}
                   model={@model} />
      </fieldset>
      <fieldset class="border border-gray bg-white rounded p-1 mt-4">
        <legend class="bg-white px-4 border border-gray rounded-lg">Text Fields</legend>
        <DataBlock columns={text_columns(assigns)}
                   record={@record}
                   model={@model} />
      </fieldset>
    </div>
    """
  end
end
