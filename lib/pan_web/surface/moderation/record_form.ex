defmodule PanWeb.Surface.Moderation.RecordForm do
  use Surface.LiveComponent
  on_mount {PanWeb.Live.Auth, :admin}

  alias Surface.Components.Form
  alias PanWeb.Surface.Admin.{Naming, ColumnsFilter}
  alias Surface.Components.Form.Field
  alias PanWeb.Surface.Submit
  alias Pan.Repo

  alias PanWeb.Surface.Admin.{
    CheckBoxField,
    TextAreaField,
    TextField,
    DateTimeSelect
  }

  alias PanWeb.Surface.Moderation.NumberField

  prop(record, :map, required: true)
  prop(model, :module, required: true)
  prop(cols, :list, required: false, default: [])

  data(changeset, :map)
  data(columns, :list, default: [])
  slot(slot_columns)

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
        send(self(), {:saved, %{message: to_string(model) <> updated_or_created(record_state)}})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def render(assigns) do
    ~F"""
    <div class="m-2" id={@id}>
      <div class="flex justify-between items-end">
        <span class="flex items-end space-x-2 text-2xl">
          <div class="text-gray-dark whitespace-nowrap">
            Edit <span class="font-semibold">{module_name(@model)}</span>
          </div>
          <h1 class="max-w-screen-lg w-full truncate">
            {Naming.title_from_record(@record)}
          </h1>
        </span>
      </div>

      <Form for={@changeset}
            opts={autocomplete: "off",
                  class: "mt-4",
                  phx_change: :validate,
                  phx_submit: :save,
                  phx_target: "#" <> @id}>
        <Field :if={!@changeset.valid?}
                name="error"
                class="inline-block px-2 mb-2 text-grapefruit bg-grapefruit/20 border border-grapefruit border-dotted">
          This record is not valid. Please check the errors below!
        </Field>

        <div class="flex flex-col space-y-4 xl:space-y-0 xl:flex-row xl:space-x-4">
          <fieldset class="border border-gray bg-gray-lightest rounded-xl p-2">
            <legend class="px-4 border border-gray rounded-lg bg-white">Numeric Fields</legend>
            {#for column <- ColumnsFilter.number_columns(assigns)}
              <NumberField name={column.field}
                           redact={@model.__schema__(:redact_fields) |> Enum.member?(column.field) } />
            {/for}
          </fieldset>
          <fieldset class="border border-gray bg-gray-lightest rounded-xl p-2">
            <legend class="px-4 border border-gray rounded-lg bg-white">Date & Time Fields</legend>
            {#for column <- ColumnsFilter.datetime_columns(assigns)}
              <DateTimeSelect name={column.field}
                              redact={@model.__schema__(:redact_fields) |> Enum.member?(column.field)} />
            {/for}
          </fieldset>
          <fieldset class="border border-gray bg-gray-lightest rounded-xl p-2">
          <legend class="px-4 border border-gray rounded-lg bg-white">Boolean Fields</legend>
            {#for column <- ColumnsFilter.boolean_columns(assigns)}
              <CheckBoxField name={column.field}
                             label={column.field}
                             redact={@model.__schema__(:redact_fields) |> Enum.member?(column.field)} />
            {/for}
          </fieldset>
        </div>

        <div class="mt-4 flex flex-col space-y-4 xl:space-y-0 xl:flex-row xl:space-x-4 w-full">
          <fieldset class="flex-1 border border-gray bg-gray-lightest rounded-xl p-2">
            <legend class="px-4 border border-gray rounded-lg bg-white">String Fields</legend>
            {#for column <- ColumnsFilter.string_columns(assigns)}
              <TextField name={column.field}
                         redact={@model.__schema__(:redact_fields) |> Enum.member?(column.field)} />
            {/for}
          </fieldset>
          <fieldset class="flex-1 border border-gray bg-gray-lightest rounded-xl p-2">
            <legend class="px-4 border border-gray rounded-lg bg-white">Text Fields</legend>
            {#for column <- ColumnsFilter.text_columns(assigns)}
              <TextAreaField name={column.field}
                             redact={@model.__schema__(:redact_fields) |> Enum.member?(column.field)} />

            {/for}
          </fieldset>
        </div>

         <Submit label="Save" />
      </Form>
    </div>
    """
  end
end
