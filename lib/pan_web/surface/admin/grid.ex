defmodule PanWeb.Surface.Admin.Grid do
  use Surface.LiveComponent
  on_mount {PanWeb.Live.Auth, :admin}
  alias PanWeb.Surface.Admin.Naming
  alias PanWeb.Surface.Admin.{SortLink, GridPresenter}
  alias Surface.Components.{Form, Link, LiveRedirect, Form.TextInput}
  require Integer

  prop(cols, :list, required: true)
  prop(sort_by, :atom, required: false, default: :id)
  prop(sort_order, :atom, required: false, default: :asc)
  prop(navigation, :boolean, required: false, default: true)
  prop(model, :module, required: true)
  prop(search_options, :map, required: false, default: %{})
  prop(page, :integer, required: false, default: 1)
  prop(like_search, :boolean, required: false, default: false)
  prop(hide_filtered, :boolean, required: false, default: true)
  prop(records, :list, required: false, default: [])
  prop(path_helper, :atom, required: false)
  prop(sort, :event, required: true)
  prop(search, :event, required: true)
  prop(delete, :event, required: true)
  prop(cycle_search_mode, :event, required: true)
  prop(search_filter, :tuple, default: {})

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

  defp to_be_dyed?(record, assigns) do
    if assigns.search_filter != {} do
      {column, value} = assigns.search_filter
      !assigns.hide_filtered && Map.get(record, column) == value
    else
      false
    end
  end

  def render(assigns) do
    ~F"""
    <div class="m-1 grid bg-gray-lightest gap-0.5 overflow-x-auto border border-gray-lightest"
         style={"grid-template-columns: 7rem " <>
                (Enum.map(@columns, &width(&1.type)) |> Enum.join(" ")) <> ";"}>
      <div class="bg-white italic grid place-content-center w-28">
        Actions
      </div>
      {#for column <- @columns}
        <div class="bg-white italic grid place-content-center text-sm text-center">
          <SortLink click={@sort}
                    {=@sort_by}
                    {=@sort_order}
                    field={column.field}>
            {column.label}
          </SortLink>
        </div>
      {/for}

      <div :if={@navigation}
        class="bg-white text-center p-1">
      Search:
      <a :on-click={@cycle_search_mode}
         class="text-link hover:text-link-dark underline" >
         {if @like_search, do: "contains", else: "exact"}
      </a>
      </div>

      {#for column <- @columns}
        <div :if={@navigation}
            class={"bg-white p-1",
                   "text-right": column.type == :integer}>
        <Form :if={column[:searchable] && @model.__schema__(:redact_fields) |> Enum.member?(column.field) |> Kernel.not}
              for={%{}}
              as={:search}
              change={@search}
              opts={autocomplete: "off"}>
          <TextInput field={column.field}
                    value={@search_options[column.field]}
                    class={"p-0.5 w-full"}
                    opts={autofocus: "autofocus", autocomplete: "off", "phx-debounce": 300} />
        </Form>
        </div>
      {/for}

      {#for {record, index} <- @records |> Enum.with_index}
        <div :if={Map.has_key?(record, :id)}
            class={"self-center flex justify-evenly w-full",
                    "bg-gray-lighter": Integer.is_odd(index) && !to_be_dyed?(record, assigns),
                    "bg-white": Integer.is_even(index) && !to_be_dyed?(record, assigns),
                    "bg-sunflower-lighter": to_be_dyed?(record, assigns)}>
          <LiveRedirect to={Naming.path %{model: @model,
                                          path_helper: @path_helper,
                                          action: :show,
                                          record: record}}
                        label="🔍" />

          <LiveRedirect to={Naming.path %{model: @model,
                                          path_helper: @path_helper,
                                          action: :edit,
                                          record: record}}
                        label="🖊️" />

          <Link to="#"
                click={@delete}
                opts={data: [confirm: "Are you sure?"],
                        "phx-value-id": record.id}
                class="block"
                label="🗑️" />
        </div>
        <div :if={!Map.has_key?(record, :id)} >
          No id to link to.
        </div>

        {#for column <- @columns}
          <GridPresenter presenter={column[:presenter]}
                        {=record}
                        field={column.field}
                        type={column.type}
                        {=index}
                        {=@model}
                        dye={to_be_dyed?(record, assigns)}/>
        {/for}
      {/for}
    </div>
    """
  end
end
