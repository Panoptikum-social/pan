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

  def type(details) do
    details.__struct__
    |> Atom.to_string
    |> String.split(".")
    |> List.last
  end

  def render(assigns) do
    {module, function, args} = assigns.model.__schema__(:autogenerate_id)
    tabs = ["Prefix",
            "Autogenerated ID",
            "Primary Keys",
            "(non virtual) Fields and Field Sources",
            "Associations",
            "Redact Fields",
            "Embedded Fields",
            "Read after Write Fields",
            "Source"]

    ~H"""
    <div class="m-2 border border-gray rounded">
      <h2 class="p-1 border-b border-gray text-center bg-gradient-to-r from-gray-light via-gray-lighter to-gray-light font-mono">
        Schema Definition for Resource
        <span class="italic">{{ Naming.module_without_namespace(@model) }}</span>
      </h2>

      <div x-data="{ selectedTab: 0 }">
        <ul class="flex flex-wrap border-b border-gray bg-gradient-to-r from-gray-lightest via-gray-lighter to-gray-light">
          <li :for.with_index={{ {title, index} <- tabs }}
              class="-mb-px ml-1.5 mt-1">
            <a class="inline-block rounded-t px-1 border-gray"
              :class="{ 'disabled text-black bg-gray-lightest border-l border-t border-r':
                        selectedTab === {{ index }},
                        'bg-gray-light text-gray-dark hover:text-gray-darker': selectedTab !== {{ index }} }"
              @click.prevent="selectedTab = {{ index }}"
              to="#">{{ title }}</a>
          </li>
        </ul>
        <div class="p-4">
          <div x-show="selectedTab === 0">
            {{ @model.__schema__(:prefix) || "no prefix" }}
          </div>

          <table x-show="selectedTab === 1">
            <thead>
              <tr>
                <th><div class="bg-white mx-2">Module</div></th>
                <th><div class="bg-white mx-2">Function</div></th>
                <th><div class="bg-white mx-2">Arguments</div></th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td><div class="bg-gray-lighter">{{ module }}</div></td>
                <td><div class="bg-gray-lighter">{{ function }}</div></td>
                <td><div class="bg-gray-lighter">{{ args }}</div></td>
              </tr>
            </tbody>
          </table>

          <div x-show="selectedTab === 2"
              :for={{ key <- @model.__schema__(:primary_key) }}>
            {{ key |> Atom.to_string }}
          </div>

          <table x-show="selectedTab === 3">
            <thead>
              <tr>
                <th><div class="bg-white mx-1">Field</div></th>
                <th><div class="bg-white mx-1">Alias</div></th>
                <th><div class="bg-white mx-1">Type</div></th>
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

          <div x-show="selectedTab === 4">
            <div x-data="{ selectedAssociation: 0 }"
                 class="-mt-3">
              <ul class="flex flex-wrap border-b border-gray bg-gradient-to-r from-gray-lightest via-gray-lighter to-gray-light">
                <li :for.with_index={{ {association, assoc_index} <- @model.__schema__(:associations) }}
                    class="-mb-px ml-1.5 mt-1">
                  <a class="inline-block rounded-t px-1 border-gray"
                    :class="{ 'disabled text-black bg-gray-lightest border-l border-t border-r':
                              selectedAssociation === {{ assoc_index }},
                              'bg-gray-light text-gray-dark hover:text-gray-darker': selectedAssociation !== {{ assoc_index }} }"
                    @click.prevent="selectedAssociation = {{ assoc_index }}"
                    to="#">{{ association |> Atom.to_string }}</a>
                </li>
              </ul>
              <div :for.with_index={{ {details, assoc_index} <- @model.__schema__(:associations) |> Enum.map(&@model.__schema__(:association, &1))}}
                   x-show="selectedAssociation === {{ assoc_index }}"
                   class="p-4 border-l border-r border-b border-gray">

                <table cellspacing="4px" class="border-separate">
                  <tr>
                    <td class="bg-white"><div class="font-mono">Type</div></td>
                    <td class="bg-white"><div>{{ type(details) }}</div></td>
                  </tr>
                  <tr>
                    <td class="bg-white"><div class="font-mono">Cardinality</div></td>
                    <td class="bg-white"><div>{{ details.cardinality |> Atom.to_string }}</div></td>
                  </tr>
                  <tr>
                    <td class="bg-white"><div class="font-mono">Defaults</div></td>
                    <td class="bg-white">
                      <div class="mx-1 flex space-x-2 justify-start" :for={{ default <- details.defaults }}>
                        {{ default |> Atom.to_string}}
                      </div>
                    </td>
                  </tr>
                  <tr>
                    <td class="bg-white"><div class="font-mono">Field</div></td>
                    <td class="bg-white"><div>{{ details.field |> Atom.to_string }}</div></td>
                  </tr>
                  <tr :if={{ Map.has_key?(details, :join_defaults) }}>
                    <td class="bg-white"><div class="font-mono">Join Defaults</div></td>
                    <td class="bg-white">
                      <div class="mx-1 flex space-x-2 justify-start" :for={{ default <- details.join_defaults }}>
                        {{ default |> Atom.to_string}}
                      </div>
                    </td>
                  </tr>
                  <tr :if={{ Map.has_key?(details, :join_keys) }}>
                    <td class="bg-white"><div class="font-mono">Join Keys</div></td>
                    <td class="bg-white">
                      <div class="mx-1 flex space-x-4" >
                        <div :for={{ {key, value} <- details.join_keys }}>{{ key |> Atom.to_string}}: {{ value |> Atom.to_string}}</div>
                      </div>
                    </td>
                  </tr>
                  <tr :if={{ Map.has_key?(details, :join_through) }}>
                    <td class="bg-white"><div class="font-mono">Join Through</div></td>
                    <td class="bg-white"><div>{{ details.join_through }}</div></td>
                  </tr>
                  <tr :if={{ Map.has_key?(details, :join_where) }}>
                    <td class="bg-white"><div class="font-mono">Join Where</div></td>
                    <td class="bg-white">
                      <div class="mx-1 flex space-x-2 justify-start" :for={{ {key, value} <- details.join_where }}>
                        {{ key |> Atom.to_string}}: {{ value |> Atom.to_string}}
                      </div>
                    </td>
                  </tr>
                  <tr>
                    <td class="bg-white"><div class="font-mono">On Cast</div></td>
                    <td class="bg-white"><div>{{ details.on_cast |> Atom.to_string }}</div></td>
                  </tr>
                  <tr>
                    <td class="bg-white"><div class="font-mono">On Replace</div></td>
                    <td class="bg-white"><div>{{ details.on_replace |> Atom.to_string }}</div></td>
                  </tr>
                  <tr :if={{ Map.has_key?(details, :on_delete) }}>
                    <td class="bg-white"><div class="font-mono">On Delete</div></td>
                    <td class="bg-white"><div>{{ details.on_delete |> Atom.to_string }}</div></td>
                  </tr>
                  <tr>
                    <td class="bg-white"><div class="font-mono">Ordered</div></td>
                    <td class="bg-white"><div>{{ details.ordered |> Atom.to_string }}</div></td>
                  </tr>
                  <tr>
                    <td class="bg-white"><div class="font-mono">Owner</div></td>
                    <td class="bg-white"><div>{{ details.owner |> Atom.to_string }}</div></td>
                  </tr>
                  <tr>
                    <td class="bg-white"><div class="font-mono">Owner Key</div></td>
                    <td class="bg-white"><div>{{ details.owner_key |> Atom.to_string }}</div></td>
                  </tr>
                  <tr>
                    <td class="bg-white"><div class="font-mono">Queryable</div></td>
                    <td class="bg-white"><div>{{ details.queryable |> Atom.to_string }}</div></td>
                  </tr>
                  <tr>
                    <td class="bg-white"><div class="font-mono">Related</div></td>
                    <td class="bg-white"><div>{{ details.related |> Atom.to_string }}</div></td>
                  </tr>
                  <tr :if={{ Map.has_key?(details, :related_key) }}>
                    <td class="bg-white"><div class="font-mono">Related Key</div></td>
                    <td class="bg-white"><div>{{ details.related_key |> Atom.to_string }}</div></td>
                  </tr>
                  <tr>
                    <td class="bg-white"><div class="font-mono">Relationship</div></td>
                    <td class="bg-white"><div>{{ details.relationship |> Atom.to_string }}</div></td>
                  </tr>
                  <tr>
                    <td class="bg-white"><div class="font-mono">Unique</div></td>
                    <td class="bg-white"><div>{{ details.unique |> Atom.to_string }}</div></td>
                  </tr>
                  <tr>
                    <td class="bg-white"><div class="font-mono">Where</div></td>
                    <td>
                      <div class="flex space-x-2 justify-start" :for={{ where <- details.where }}>
                      {{ where |> Atom.to_string }}
                      </div>
                    </td>
                  </tr>
                </table>
              </div>
            </div>
          </div>

          <div x-show="selectedTab === 5">
            <div :for={{ field <- @model.__schema__(:redact_fields) }}>
              {{ field |> Atom.to_string() }}
            </div>
            <div :if={{ @model.__schema__(:redact_fields) == [] }}>none</div>
          </div>

          <div x-show="selectedTab === 6">
            <div :for={{ field <- @model.__schema__(:embeds) }}>
              {{ field |> Atom.to_string() }}
            </div>
            <div :if={{ @model.__schema__(:embeds) == [] }}>none</div>
          </div>

          <div x-show="selectedTab === 7">
            <div :for={{ field <- @model.__schema__(:read_after_writes) }}>
              {{ field |> Atom.to_string() }}
            </div>
            <div :if={{ @model.__schema__(:read_after_writes) == [] }}>none</div>
          </div>

          <div x-show="selectedTab === 8">
            {{ @model.__schema__(:source) }}
          </div>
        </div>
      </div>
    </div>
    """
  end
end
