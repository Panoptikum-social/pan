defmodule PanWeb.Surface.Admin.RecordForm do
  use Surface.LiveComponent
  alias PanWeb.Router.Helpers, as: Routes
  alias Surface.Components.Form
  alias Surface.Components.Form.Field
  import PanWeb.Surface.Admin.ColumnsFilter
  alias PanWeb.Surface.{TextField, Submit}
  alias PanWeb.Surface.Admin.{CheckBoxField, NumberField, DateTimeField, TextAreaField}

  prop(record, :map, required: true)
  prop(resource, :module, required: true)
  prop(path_helper, :atom, required: true)

  data(changeset, :map)
  slot(columns)

  def update(assigns, socket) do
    {:ok,
     assign(socket |> assign(assigns),
       changeset: assigns.record |> assigns.resource.changeset()
     )}
  end

  def name(struct) do
    struct.__struct__
    |> to_string()
    |> String.split(".")
    |> List.last()
  end

  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-2xl">
        <span class="text-gray">
          Edit <span class="font-semibold">{{ name(@record) }}</span>
        </span> &nbsp; {{ @record.title }}
      </h2>

      <Form action={{ Function.capture(Routes, @path_helper, 2).(@socket, :create) }}
            for={{ @changeset }}
            opts={{ autocomplete: "off", class: "mt-8" }}>

        <Field :if={{ @changeset.action }}
                name="error"
                class="alert alert-danger">
          An error occured. Please check the errors below!
        </Field>

        <div class="flex space-x-8">
          <div>
            <CheckBoxField :for={{ column <- boolean_columns(assigns) }}
                          name={{ column.field }}
                          label={{ column.field }}/>
          </div>
          <div>
            <NumberField :for={{ column <- number_columns(assigns) }}
                          name={{ column.field }} />
          </div>
          <div>
            <DateTimeField :for={{ column <- datetime_columns(assigns) }}
                            name={{ column.field }} />
          </div>
          <div>
            <TextField :for={{ column <- string_columns(assigns) }}
                        name={{ column.field }} />
          </div>
        </div>
        <div>
          <TextAreaField :for={{ column <- text_columns(assigns) }}
                         name={{ column.field }} />
        </div>
         <Submit label="Save" />
      </Form>
    </div>
    """
  end
end
