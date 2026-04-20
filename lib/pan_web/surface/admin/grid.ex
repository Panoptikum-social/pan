defmodule PanWeb.Surface.Admin.Grid do
  use PanWeb, :html

  alias PanWeb.Surface.Admin.Naming
  alias PanWeb.Surface.Admin.{SortLink, GridPresenter}
  require Integer

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

  defp to_be_dyed?(record, assigns) do
    if assigns.search_filter != {} do
      {column, value} = assigns.search_filter
      !assigns.hide_filtered && Map.get(record, column) == value
    else
      false
    end
  end

  attr :cols, :list, required: true
  attr :sort_by, :atom, default: :id
  attr :sort_order, :atom, default: :asc
  attr :navigation, :boolean, default: true
  attr :model, :any, required: true
  attr :search_options, :map, default: %{}
  attr :page, :integer, default: 1
  attr :like_search, :boolean, default: false
  attr :hide_filtered, :boolean, default: true
  attr :records, :list, default: []
  attr :path_helper, :atom, default: nil
  attr :sort, :string, required: true
  attr :search, :string, required: true
  attr :delete, :string, required: true
  attr :cycle_search_mode, :string, required: true
  attr :search_filter, :any, default: {}
  attr :target, :any, required: true

  def render(assigns) do
    ~H"""
    <div class="m-1 grid bg-gray-lightest gap-0.5 overflow-x-auto border border-gray-lightest"
         style={"grid-template-columns: 7rem #{Enum.map(@cols, &width(&1.type)) |> Enum.join(" ")};"}>
      <div class="bg-white italic grid place-content-center w-28">
        Actions
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

      <div :if={@navigation} class="bg-white text-center p-1">
        Search:
        <a phx-click={@cycle_search_mode}
           phx-target={@target}
           class="text-link hover:text-link-dark underline">
          {if @like_search, do: "contains", else: "exact"}
        </a>
      </div>

      <div :for={column <- @cols}
           :if={@navigation}
           class={["bg-white p-1", if(column.type == :integer, do: "text-right")]}>
        <.form :if={column[:searchable] && @model.__schema__(:redact_fields) |> Enum.member?(column.field) |> Kernel.not}
               for={%{}}
               as={:search}
               phx-change={@search}
               phx-target={@target}
               autocomplete="off">
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
        <div :if={Map.has_key?(record, :id)}
             class={[
               "self-center flex justify-evenly w-full",
               if(Integer.is_odd(index) && !to_be_dyed?(record, assigns), do: "bg-gray-lighter"),
               if(Integer.is_even(index) && !to_be_dyed?(record, assigns), do: "bg-white"),
               if(to_be_dyed?(record, assigns), do: "bg-sunflower-lighter")
             ]}>
          <.link navigate={Naming.path(%{model: @model, path_helper: @path_helper, action: :show, record: record})}>🔍</.link>
          <.link navigate={Naming.path(%{model: @model, path_helper: @path_helper, action: :edit, record: record})}>🖊️</.link>
          <.link href="#"
                 phx-click={@delete}
                 phx-target={@target}
                 phx-value-id={record.id}
                 data-confirm="Are you sure?"
                 class="block">🗑️</.link>
        </div>
        <div :if={!Map.has_key?(record, :id)}>
          No id to link to.
        </div>

        <GridPresenter.render :for={column <- @cols}
                              presenter={column[:presenter]}
                              record={record}
                              field={column.field}
                              type={column.type}
                              index={index}
                              model={@model}
                              dye={to_be_dyed?(record, assigns)} />
      <% end %>
    </div>
    """
  end
end
