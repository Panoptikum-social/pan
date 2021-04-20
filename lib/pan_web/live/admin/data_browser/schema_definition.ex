defmodule PanWeb.Live.Admin.Databrowser.SchemaDefinition do
  use Surface.LiveView,
    layout: {PanWeb.LayoutView, "live_admin.html"},
    container: {:div, class: "flex-1"}

  alias PanWeb.Surface.Admin.Naming
  require Integer

  def mount(%{"resource" => resource}, _session, socket) do
    model = Naming.model_from_resource(resource)
    {:ok, assign(socket, resource: resource, model: model)}
  end

  def render(assigns) do
    ~H"""
    <div class="m-2 border border-gray rounded">
      <h2 class="p-1 border-b border-gray text-center bg-gradient-to-r from-gray-light via-gray-lighter to-gray-light font-mono">
        Schema Definition for Resource
        <span class="italic">{{ Naming.module_without_namespace(@model) }}</span>
      </h2>

      <div class="m-2">
        <dl>
          <dt class="font-mono">Prefix</dt>
          <dd class="ml-8">{{ @model.__schema__(:prefix) || "no prefix" }}</dd>

          <dt class="font-mono">Primary Keys</dt>
          <dd :for={{ key <- @model.__schema__(:primary_key) }}
              class="ml-8">
            {{ key |> Atom.to_string() }}
          </dd>

          <dt class="font-mono">(non virtual) Fields and Field Sources</dt>
          <dd class="ml-8">
            <table>
              <thead>
                <tr>
                  <th>
                    <div class="bg-white mx-1">Field</div> </th>
                  <th>
                    <div class="bg-white mx-1">Alias</div> </th>
                  <th>
                    <div class="bg-white mx-1">Type</div>
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr :for.with_index={{ {field, index} <- @model.__schema__(:fields) }}>
                  <td>
                    <div class={{ "mx-1",
                                  "bg-white": Integer.is_odd(index),
                                  "bg-gray-lighter": Integer.is_even(index) }}>
                      {{ field |> Atom.to_string() }}
                    </div>
                  </td>
                  <td>
                    <div class={{ "mx-1",
                                  "bg-white": Integer.is_odd(index),
                                  "bg-gray-lighter": Integer.is_even(index) }}>
                      {{ @model.__schema__(:field_source, field) |> Atom.to_string() }}
                    </div>
                  </td>
                  <td>
                    <div class={{ "mx-1",
                        "bg-white": Integer.is_odd(index),
                        "bg-gray-lighter": Integer.is_even(index) }}>
                      {{ @model.__schema__(:type, field) |> Atom.to_string() }}
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </dd>
        </dl>

        <dt class="font-mono">Embedded Fields</dt>
        <dd :for={{ field <- @model.__schema__(:embeds) }}
            class="ml-8">
          {{ field |> Atom.to_string() }}
        </dd>
        <dd :if={{ @model.__schema__(:embeds) == [] }}
            class="ml-8">
          none
        </dd>

        <dt class="font-mono">Read after Write Fields</dt>
        <dd :for={{ field <- @model.__schema__(:read_after_writes) }}
            class="ml-8">
          {{ field |> Atom.to_string() }}
        </dd>
        <dd :if={{ @model.__schema__(:read_after_writes) == [] }}
            class="ml-8">
          none
        </dd>

      </div>
    </div>
    """
  end
end

# __schema__(:source) - Returns the source as given to schema/2;
# __schema__(:associations) - Returns a list of all association field names;
# __schema__(:association, assoc) - Returns the association reflection of the given assoc;
# __schema__(:embed, embed) - Returns the embedding reflection of the given embed;
# __schema__(:autogenerate_id) - Primary key that is auto generated on insert;
# __schema__(:redact_fields) - Re
