defmodule PanWeb.Surface.Admin.RecordForm do
  use Surface.LiveComponent
  alias PanWeb.Router.Helpers, as: Routes
  alias Surface.Components.Form
  alias Surface.Components.Form.Field
  import PanWeb.Surface.Admin.ColumnsFilter
  alias PanWeb.Surface.{TextField, CheckBoxField, NumberField, DateTimeField, Submit}

  prop record, :map, required: true
  prop resource, :module, required: true
  prop path_helper, :atom, required: true

  data changeset, :map
  slot columns

  def update(assigns, socket) do
    resource = assigns.resource
    {:ok, assign(socket |> assign(assigns),
                 changeset: struct(resource) |> resource.changeset())}
  end

  def name(struct) do
    struct.__struct__
    |> to_string()
    |> String.split(".")
    |> List.last()
  end

  def render(assigns) do
    ~H"""
    <div class="bg-white">
      <h2 class="text-2xl">
        <span class="text-gray">
          Edit <span class="font-semibold">{{ name(@record) }}</span>
        </span> &nbsp; {{ @record.title }}
      </h2>

      <Form action={{ Function.capture(Routes, @path_helper, 2).(@socket, :create) }}
            for={{ @changeset }}
            opts={{ autocomplete: "off" }}>

        <Field :if={{ @changeset.action }}
               name="error"
               class="alert alert-danger">
          An error occured. Please check the errors below!
        </Field>

        <CheckBoxField :for={{ column <- boolean_columns(assigns) }}
                       name={{ column.field }}
                       label={{ column.field }}/>
        <NumberField :for={{ column <- number_columns(assigns) }}
                     name={{ column.field }} />
        <DateTimeField :for={{ column <- datetime_columns(assigns) }}
                       name={{ column.field }} />
        <TextField :for={{ column <- string_columns(assigns) }}
                   name={{ column.field }} />
        <Submit label="Save" />
      </Form>
    </div>
    """
  end
end
