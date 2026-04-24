defmodule PanWeb.Admin.DataTable do
  use PanWeb, :html

  alias PanWeb.Admin.SortLink
  alias PanWeb.Admin.GridPresenterWithDetails
  require Integer

  defp width(:id), do: "6rem"
  defp width(Ecto.UUID), do: "4rem"
  defp width(:integer), do: "4rem"
  defp width(:float), do: "5rem"
  defp width(:date), do: "6rem"
  defp width(:datetime), do: "12rem"
  defp width(:naive_datetime), do: "12rem"
  defp width(:string), do: "16rem"
  defp width(Ecto.EctoText), do: "16rem"
  defp width(:boolean), do: "4rem"

  defp dyed?(record, assigns) do
    if assigns.search_filter != {} do
      {column, value_s} = assigns.search_filter
      !assigns.hide_filtered && associated?(record, column, value_s)
    else
      false
    end
  end

  def associated?(record, column, values) when is_list(values) do
    Map.get(record, column) in values
  end

  def associated?(record, column, value) when is_integer(value) do
    Map.get(record, column) == value
  end

  defp selected?(record, selected_records) do
    Enum.any?(selected_records, &all_keys_matching?(record, &1))
  end

  defp all_keys_matching?(record, selected_record) do
    Enum.all?(Map.keys(selected_record), &(Map.get(record, &1) == Map.get(selected_record, &1)))
  end

  attr :id, :string, default: nil
  attr :cols, :list, required: true
  attr :sort_by, :atom, default: :id
  attr :sort_order, :atom, default: :asc
  attr :buttons, :list, required: true
  attr :model, :any, required: true
  attr :search_options, :map, default: %{}
  attr :search_mode, :atom, default: :exact
  attr :hide_filtered, :boolean, default: true
  attr :records, :list, default: []
  attr :path_helper, :atom, default: nil
  attr :sort, :string, required: true
  attr :select, :string, required: true
  attr :search, :string, required: true
  attr :cycle_search_mode, :string, required: true
  attr :search_filter, :any, default: {}
  attr :selected_records, :list, default: []
  attr :primary_key, :list, default: [:id]
  attr :target, :any, required: true

  def render(assigns) do
    ~H"""
    <div class="m-1 pb-1 grid bg-gray-lightest gap-0.5 overflow-x-auto border border-gray-lightest"
         style={"grid-template-columns: 6rem #{Enum.map(@cols, &width(&1.type)) |> Enum.join(" ")};"}>
      <div class="bg-white italic grid place-content-center text-sm text-center px-1">
        <span :if={:search in @buttons}>Search Mode</span>
      </div>
      <div :for={column <- @cols} class="bg-white italic grid place-content-center text-sm text-center">
        <SortLink.render click={@sort}
                         target={@target}
                         sort_by={@sort_by}
                         sort_order={@sort_order}
                         field={column.field}>
          {column.label}
        </SortLink.render>
      </div>

      <div :if={:search in @buttons}
           class="bg-gray-lighter text-center p-1">
        <a phx-click={@cycle_search_mode}
           phx-target={@target}
           class="text-link hover:text-link-dark underline">
          {@search_mode |> Atom.to_string() |> String.replace("_", " ")}
        </a>
      </div>

      <div :for={column <- @cols}
           :if={:search in @buttons}
           class={["bg-gray-lighter p-1", if(column.type == :integer, do: "text-right")]}>
        <.form :if={column[:searchable] && @model.__schema__(:redact_fields) |> Enum.member?(column.field) |> Kernel.not}
               for={%{}}
               as={:search}
               phx-change={@search}
               phx-target={@target}
               autocomplete="off"
               onkeydown="return event.key != 'Enter';">
          <input type="text"
                 name={"search[#{column.field}]"}
                 value={@search_options[column.field]}
                 class="p-0.5 w-full"
                 autofocus="autofocus"
                 autocomplete="off"
                 phx-debounce="300" />
        </.form>
      </div>

      <%= for {record, index} <- @records |> Enum.with_index do %>
        <div class={[
               "text-center",
               if(Integer.is_odd(index) && !dyed?(record, assigns), do: "bg-gray-lighter"),
               if(Integer.is_even(index) && !dyed?(record, assigns), do: "bg-white"),
               if(dyed?(record, assigns), do: "bg-sunflower-lighter")
             ]}>
          <input :if={Map.has_key?(record, :id)}
                 type="checkbox"
                 class="my-1.5"
                 checked={selected?(record, @selected_records)}
                 phx-click={@select}
                 phx-target={@target}
                 phx-value-id={record.id} />

          <input :if={length(@primary_key) == 2}
                 type="checkbox"
                 class="my-1.5"
                 checked={selected?(record, @selected_records)}
                 phx-click={@select}
                 phx-target={@target}
                 phx-value-one={Map.get(record, hd(@primary_key))}
                 phx-value-two={Map.get(record, hd(tl(@primary_key)))} />
        </div>

        <GridPresenterWithDetails.render :for={column <- @cols}
                              presenter={column[:presenter]}
                              record={record}
                              field={column.field}
                              type={column.type}
                              index={index}
                              model={@model}
                              dye={dyed?(record, assigns)} />
      <% end %>
    </div>
    """
  end
end
