defmodule PanWeb.Surface.Admin.RecordForm do
  use Surface.LiveComponent
  alias PanWeb.Router.Helpers, as: Routes
  alias Surface.Components.{Form, LiveRedirect}
  alias Surface.Components.Form.Field
  import PanWeb.Surface.Admin.ColumnsFilter
  alias PanWeb.Surface.Submit
  alias Pan.Repo

  alias PanWeb.Surface.Admin.{
    CheckBoxField,
    NumberField,
    TextAreaField,
    TextField,
    DateTimeSelect
  }

  prop(record, :map, required: true)
  prop(model, :module, required: true)
  prop(path_helper, :atom, required: true)
  prop(cols, :list, required: false, default: [])

  data(changeset, :map)
  data(columns, :list, default: [])
  slot(slot_columns)

  def update(assigns, socket) do
    columns = if assigns.cols == [], do: assigns.slot_columns, else: assigns.cols


    {:ok,
     assign(socket |> assign(assigns),
       columns: columns,
       changeset: assigns.record |> assigns.model.changeset() |> Map.put(:action, :insert)
     )}
  end

  def module_name(model) do
    model
    |> to_string()
    |> String.split(".")
    |> List.last()
  end

  def updated_or_created(nil), do: " created"
  def updated_or_created(_), do: " updated"

  def handle_event("validate", params, socket) do
    model = socket.assigns.model
    resource_name = Phoenix.Naming.resource_name(model)

    changeset =
      model.changeset(Kernel.struct(model), params[resource_name])
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("save", params, socket) do
    model = socket.assigns.model
    resource_name = Phoenix.Naming.resource_name(model)
    record_id = params[resource_name]["id"]

    record = if record_id, do: Repo.get(model, record_id), else: Kernel.struct(model)
    changeset = model.changeset(record, params[resource_name])
    response = if record_id, do: Repo.update(changeset), else: Repo.insert(changeset)

    case response do
      {:ok, record} ->
        record_show_path =
          Function.capture(Routes, socket.assigns.path_helper, 3).(socket, :show, record)

        send(
          self(),
          {:redirect,
           %{
             path: record_show_path,
             flash_type: :info,
             message: to_string(socket.assigns.model) <> updated_or_created(record_id)
           }}
        )

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def render(assigns) do
    ~H"""
    <div id={{ @id }}>
      <div class="flex justify-between items-end">
        <span class="flex items-end space-x-2 text-2xl">
          <span class="text-gray-dark">
            Edit <span class="font-semibold">{{ module_name(@model) }}</span>
          </span>
          <h2>{{ @record.title }}</h2>
        </span>
        <span>
          <LiveRedirect to={{ Function.capture(Routes, @path_helper, 2).(@socket, :index) }}
                        class="text-link hover:text-link-dark underline">
            {{ module_name(@model) }} List
          </LiveRedirect> &nbsp;
          <LiveRedirect :if={{ @record.id }}
                        to={{ Function.capture(Routes, @path_helper, 3).(@socket, :show, @record) }}
                        class="text-link hover:text-link-dark underline">
            Show {{ module_name(@model) }}
          </LiveRedirect>
        </span>
      </div>

      <Form for={{ @changeset }}
            opts={{ autocomplete: "off",
                    class: "mt-4",
                    phx_change: :validate,
                    phx_submit: :save,
                    phx_target: "#" <> @id }}>
        <Field :if={{ !@changeset.valid? }}
                name="error"
                class="inline-block px-2 mb-2
                text-grapefruit bg-grapefruit bg-opacity-20
                border border-grapefruit border-dotted">
          This record is not valid. Please check the errors below!
        </Field>

        <div class="flex flex-col space-y-4 xl:space-y-0 xl:flex-row xl:space-x-4">
          <fieldset class="border border-gray bg-gray-lightest rounded-xl p-2">
            <legend class="px-4 border border-gray rounded-lg bg-white">Numeric Fields</legend>
            <NumberField :for={{ column <- number_columns(assigns) }}
                          name={{ column.field }} />
          </fieldset>
          <fieldset class="border border-gray bg-gray-lightest rounded-xl p-2">
            <legend class="px-4 border border-gray rounded-lg bg-white">Date & Time Fields</legend>
            <DateTimeSelect :for={{ column <- datetime_columns(assigns) }}
                            name={{ column.field }} />
          </fieldset>
          <fieldset class="border border-gray bg-gray-lightest rounded-xl p-2">
          <legend class="px-4 border border-gray rounded-lg bg-white">Boolean Fields</legend>
            <CheckBoxField :for={{ column <- boolean_columns(assigns) }}
                          name={{ column.field }}
                          label={{ column.field }}/>
          </fieldset>
        </div>

        <div class="mt-4 flex flex-col space-y-4 xl:space-y-0 xl:flex-row xl:space-x-4 w-full">
          <fieldset class="flex-1 border border-gray bg-gray-lightest rounded-xl p-2">
            <legend class="px-4 border border-gray rounded-lg bg-white">String Fields</legend>
            <TextField :for={{ column <- string_columns(assigns) }}
                      name={{ column.field }} />
          </fieldset>
          <fieldset class="flex-1 border border-gray bg-gray-lightest rounded-xl p-2">
            <legend class="px-4 border border-gray rounded-lg bg-white">Text Fields</legend>
            <TextAreaField :for={{ column <- text_columns(assigns) }}
                          name={{ column.field }} />
          </fieldset>
        </div>

         <Submit label="Save" />
      </Form>
    </div>
    """
  end
end
