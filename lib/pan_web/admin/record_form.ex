defmodule PanWeb.Admin.RecordForm do
  use PanWeb, :live_component

  alias PanWeb.Endpoint
  alias Pan.Repo

  import PanWeb.CoreComponents

  alias PanWeb.Admin.Naming
  alias PanWeb.Admin.ColumnsFilter

  alias PanWeb.Components.Admin.{
    CheckBoxField,
    DateTimeSelect,
    NumberField,
    TextAreaField,
    TextField
  }

  def update(assigns, socket) do
    columns = if assigns.cols == [], do: assigns.slot_columns, else: assigns.cols

    socket =
      assign(socket, assigns)
      |> assign(
        columns: columns,
        changeset: assigns.model.changeset(assigns.record) |> Map.put(:action, :insert)
      )

    {:ok, socket}
  end

  def module_name(model) do
    model
    |> to_string
    |> String.split(".")
    |> List.last()
  end

  def updated_or_created(:loaded), do: " updated"
  def updated_or_created(:built), do: " created"

  def handle_event("validate", params, socket) do
    model = socket.assigns.model
    resource = Phoenix.Naming.resource_name(model)

    changeset =
      model.changeset(Kernel.struct(model), params[resource])
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("save", params, socket) do
    model = socket.assigns.model
    path_helper = socket.assigns.path_helper
    path_action = socket.assigns.path_action
    resource = Phoenix.Naming.resource_name(model)
    record_state = socket.assigns.record.__meta__.state
    record = socket.assigns.record
    changeset = model.changeset(record, params[resource])

    response =
      case record_state do
        :loaded -> Repo.update(changeset)
        :built -> Repo.insert(changeset)
      end

    case response do
      {:ok, _} ->
        send(
          self(),
          {:redirect,
           %{
             path:
               Naming.path(%{
                 socket: socket,
                 model: model,
                 action: path_action,
                 path_helper: path_helper
               }),
             flash_type: :info,
             message: to_string(model) <> updated_or_created(record_state)
           }}
        )

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  attr :record, :map, required: true
  attr :model, :atom, required: true
  attr :path_helper, :atom, default: nil
  attr :path_action, :atom, default: :index
  attr :cols, :list, default: []

  slot :slot_columns

  def render(assigns) do
    ~H"""
    <div class="m-2" id={@id}>
      <div class="flex justify-between items-end">
        <span class="flex items-end space-x-2 text-2xl">
          <div class="text-gray-dark whitespace-nowrap">
            Edit <span class="font-semibold">{module_name(@model)}</span>
          </div>
          <h1 class="max-w-5xl w-full truncate">
            {Naming.title_from_record(@record)}
          </h1>
        </span>
        <span>
          <.link :if={Map.has_key?(@record, :id) && @record.id}
                 navigate={Naming.path %{socket: Endpoint,
                                         model: @model,
                                         action: :show,
                                         path_helper: @path_helper,
                                         record: @record}}
                 class="text-link hover:text-link-dark underline">
            Show&nbsp;{module_name(@model)}
          </.link> |
          <.link navigate={Naming.path %{model: @model,
                                         action: :index,
                                         path_helper: @path_helper}}
                 class="text-link hover:text-link-dark underline">
            {module_name(@model)}&nbsp;List
          </.link> &nbsp;
        </span>
      </div>
      <.form for={@changeset}
            autocomplete="off"
            class="mt-4"
            phx-change="validate"
            phx-submit="save"
            phx-target={"#" <> @id}>

        <.error :if={!@changeset.valid?}>
          This record is not valid. Please check the errors below!
        </.error>

        <div class="flex flex-col space-y-4 xl:space-y-0 xl:flex-row xl:space-x-4">
          <fieldset class="border border-gray bg-gray-lightest rounded-xl p-2">
            <legend class="px-4 border border-gray rounded-lg bg-white">Numeric Fields</legend>
            <NumberField.render :for={column <- ColumnsFilter.number_columns(assigns)}
                                name={column.field}
                                redact={@model.__schema__(:redact_fields) |> Enum.member?(column.field)} />
          </fieldset>
          <fieldset class="border border-gray bg-gray-lightest rounded-xl p-2">
            <legend class="px-4 border border-gray rounded-lg bg-white">Date & Time Fields</legend>
            <DateTimeSelect.render :for={column <- ColumnsFilter.datetime_columns(assigns)}
                                   name={column.field}
                                   redact={@model.__schema__(:redact_fields) |> Enum.member?(column.field)} />
          </fieldset>
          <fieldset class="border border-gray bg-gray-lightest rounded-xl p-2">
            <legend class="px-4 border border-gray rounded-lg bg-white">Boolean Fields</legend>
            <CheckBoxField.render :for={column <- ColumnsFilter.boolean_columns(assigns)}
                                  name={column.field}
                                  label={column.field}
                                  redact={@model.__schema__(:redact_fields) |> Enum.member?(column.field)} />
          </fieldset>
        </div>

        <div class="mt-4 flex flex-col space-y-4 xl:space-y-0 xl:flex-row xl:space-x-4 w-full">
          <fieldset class="flex-1 border border-gray bg-gray-lightest rounded-xl p-2">
            <legend class="px-4 border border-gray rounded-lg bg-white">String Fields</legend>
            <TextField.render :for={column <- ColumnsFilter.string_columns(assigns)}
                              name={column.field}
                              redact={@model.__schema__(:redact_fields) |> Enum.member?(column.field)} />
          </fieldset>
          <fieldset class="flex-1 border border-gray bg-gray-lightest rounded-xl p-2">
            <legend class="px-4 border border-gray rounded-lg bg-white">Text Fields</legend>
            <TextAreaField.render :for={column <- ColumnsFilter.text_columns(assigns)}
                                  name={column.field}
                                  redact={@model.__schema__(:redact_fields) |> Enum.member?(column.field)} />
          </fieldset>
        </div>

        <.button type="submit" label="Save" />

      </.form>
    </div>
    """
  end
end
