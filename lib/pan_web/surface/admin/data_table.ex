defmodule PanWeb.Surface.Admin.DataTable do
  use Surface.LiveComponent
  alias PanWeb.Surface.Admin.{SortLink, GridPresenter}
  alias Surface.Components.{Form, Link, Form.TextInput}
  require Integer

  prop(cols, :list, required: true)
  prop(sort_by, :atom, required: false, default: :id)
  prop(sort_order, :atom, required: false, default: :asc)
  prop(show_navigation, :boolean, required: false, default: true)
  prop(model, :module, required: true)
  prop(search_options, :map, required: false, default: %{})
  prop(page, :integer, required: false, default: 1)
  prop(search_mode, :atom, required: false, default: :exact)
  prop(hide_filtered, :boolean, required: false, default: true)
  prop(records, :list, required: false, default: [])
  prop(path_helper, :atom, required: false)
  prop(target, :string, required: false)
  prop(search_filter, :tuple, default: {})
  prop(selected_records, :list, default: [])
  prop(primary_key, :list, default: [:id])

  data(columns, :list, default: [])
  slot(slot_columns)

  def update(assigns, socket) do
    columns = if assigns.cols == [], do: assigns.slot_columns, else: assigns.cols
    {:ok, assign(socket, assigns) |> assign(columns: columns)}
  end

  defp width(type) do
    case type do
      :id -> "6rem"
      :integer -> "4rem"
      :date -> "6rem"
      :datetime -> "12rem"
      :naive_datetime -> "12rem"
      :string -> "16rem"
      Ecto.EctoText -> "16rem"
      :boolean -> "4rem"
    end
  end

  defp dyed?(record, assigns) do
    if assigns.search_filter != {} do
      {column, value} = assigns.search_filter
      !assigns.hide_filtered && Map.get(record, column) == value
    else
      false
    end
  end

  defp selected?(record, selected_records) do
    Enum.any?(selected_records, &(all_keys_maching?(record, &1)))
  end

  defp all_keys_maching?(record, selected_record) do
    Enum.all?(Map.keys(selected_record), &(Map.get(record, &1) == Map.get(selected_record, &1)))
  end

  defp grid_style(columns, show_navigation) do
    if show_navigation do
      "grid-template-columns: 6rem " <> (Enum.map(columns, &width(&1.type)) |> Enum.join(" ")) <> ";"
    else
      "grid-template-columns: " <> (Enum.map(columns, &width(&1.type)) |> Enum.join(" ")) <> ";"
    end
  end

  def render(assigns) do
    ~H"""
    <div class="m-1 grid bg-gray-lightest gap-0.5 overflow-x-auto border border-gray-lightest"
         style={{ grid_style(@columns, @show_navigation) }}>
      <div :if={{ @show_navigation}}
           class="bg-white italic grid place-content-center text-sm text-center px-1">
         Search Mode
      </div>
      <div :for={{ column <- @columns }}
           class="bg-white italic grid place-content-center text-sm text-center">
      <SortLink sort_by={{ @sort_by }}
                field={{ column.field }}
                sort_order={{ @sort_order }}
                target={{ "#" <> @target }}>
        {{ column.label }}
      </SortLink>
      </div>

      <div :if={{ @show_navigation }}
           class="bg-gray-lighter text-center p-1">
      <Link to="#"
            click={{"cycle_search_mode", target: "#" <> @target }}
            label={{ @search_mode |> Atom.to_string |> String.replace("_", " ") }}
            class="text-link hover:text-link-dark underline" />
      </div>

      <div :if={{ @show_navigation }}
           :for={{ column <- @columns }}
           class={{ "bg-gray-lighter p-1",
                    "text-right": column.type == :integer}}>
      <Form :if={{ column[:searchable] && @model.__schema__(:redact_fields) |> Enum.member?(column.field) |> Kernel.not }}
            for={{ :search }}
            change={{"search", target: "#" <> @target }}
            opts={{ autocomplete: "off" }}>
        <TextInput field={{ column.field }}
                  value={{ @search_options[column.field] }}
                  class={{ "p-0.5 w-full"}}
                  opts={{ autofocus: "autofocus",
                          autocomplete: "off",
                          "phx-debounce": 300 }} />
      </Form>
      </div>

      <For each={{ {record, index} <- Enum.with_index(@records) }}>
        <div :if={{ @show_navigation }}
             class={{ "text-center",
                      "bg-gray-lighter": Integer.is_odd(index) && !dyed?(record, assigns),
                      "bg-white": Integer.is_even(index) && !dyed?(record, assigns),
                      "bg-sunflower-lighter": dyed?(record, assigns) }}>
          <input :if={{ Map.has_key?(record, :id) }}
                 type="checkbox"
                 class="my-1.5"
                 :attrs={{ checked: selected?(record, @selected_records) }}
                 phx-click="select"
                 phx-value-id={{ record.id }}
                 phx-target={{"#" <> @target }} />

          <input :if={{ length(@primary_key) == 2 }}
                 type="checkbox"
                 class="my-1.5"
                 :attrs={{ checked: selected?(record, @selected_records) }}
                 phx-click="select"
                 phx-value-one={{ Map.get(record, List.first(@primary_key)) }}
                 phx-value-two={{ Map.get(record, List.last(@primary_key)) }}
                 phx-target={{"#" <> @target }} />
        </div>

        <GridPresenter :for={{ column <- @columns }}
                        presenter={{ column[:presenter]}}
                        record={{ record }}
                        field={{ column.field }}
                        type={{ column.type }}
                        index={{ index }}
                        model={{ @model }}
                        dye={{ dyed?(record, assigns) }}/>
      </For>
    </div>
    """
  end
end
