defmodule PanWeb.Surface.Admin.DataTable do
  use Surface.LiveComponent
  on_mount {PanWeb.Live.Auth, :admin}

  alias PanWeb.Surface.Admin.{SortLink, GridPresenter}
  alias Surface.Components.{Form, Form.TextInput}
  require Integer

  prop(cols, :list, required: true)
  prop(sort_by, :atom, required: false, default: :id)
  prop(sort_order, :atom, required: false, default: :asc)
  prop(buttons, :list, required: true)
  prop(model, :module, required: true)
  prop(search_options, :map, required: false, default: %{})
  prop(search_mode, :atom, required: false, default: :exact)
  prop(hide_filtered, :boolean, required: false, default: true)
  prop(records, :list, required: false, default: [])
  prop(path_helper, :atom, required: false)
  prop(sort, :event, required: true)
  prop(select, :event, required: true)
  prop(search, :event, required: true)
  prop(cycle_search_mode, :event, required: true)
  prop(search_filter, :tuple, default: {})
  prop(selected_records, :list, default: [])
  prop(primary_key, :list, default: [:id])

  data(columns, :list, default: [])
  slot(slot_columns)

  def update(assigns, socket) do
    columns = if assigns.cols == [], do: assigns.slot_columns, else: assigns.cols
    {:ok, assign(socket, assigns) |> assign(columns: columns)}
  end

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
    Enum.any?(selected_records, &all_keys_maching?(record, &1))
  end

  defp all_keys_maching?(record, selected_record) do
    Enum.all?(Map.keys(selected_record), &(Map.get(record, &1) == Map.get(selected_record, &1)))
  end

  def render(assigns) do
    ~F"""
    <div class="m-1 pb-1 grid bg-gray-lightest gap-0.5 overflow-x-auto border border-gray-lightest"
         style={"grid-template-columns: 6rem #{Enum.map(@columns, &width(&1.type)) |> Enum.join(" ")};"}>
      <div class="bg-white italic grid place-content-center text-sm text-center px-1">
         <span :if={:search in @buttons}>Search Mode</span>
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

      <div :if={:search in @buttons}
           class="bg-gray-lighter text-center p-1">
        <a :on-click={@cycle_search_mode}
           class="text-link hover:text-link-dark underline">
          {@search_mode |> Atom.to_string |> String.replace("_", " ")}
        </a>
      </div>

      {#for column <- @columns}
        <div :if={:search in @buttons}
            class={"bg-gray-lighter p-1",
                   "text-right": column.type == :integer}>
          <Form :if={column[:searchable] && @model.__schema__(:redact_fields) |> Enum.member?(column.field) |> Kernel.not}
                for={:search}
                change={@search}
                opts={autocomplete: "off", onkeydown: "return event.key != 'Enter';"}
                >
            <TextInput field={column.field}
                       value={@search_options[column.field]}
                       class={"p-0.5 w-full"}
                       opts={autofocus: "autofocus",
                             autocomplete: "off",
                             "phx-debounce": 300} />
          </Form>
        </div>
      {/for}

      {#for {record, index} <- @records |> Enum.with_index}
        <div class={"text-center",
                    "bg-gray-lighter": Integer.is_odd(index) && !dyed?(record, assigns),
                    "bg-white": Integer.is_even(index) && !dyed?(record, assigns),
                    "bg-sunflower-lighter": dyed?(record, assigns)}>
          <input :if={Map.has_key?(record, :id)}
                 type="checkbox"
                 class="my-1.5"
                 checked={selected?(record, @selected_records)}
                 :on-click={@select}
                 phx-value-id={record.id} />

          <input :if={length(@primary_key) == 2}
                 type="checkbox"
                 class="my-1.5"
                 checked={selected?(record, @selected_records)}
                 :on-click={@select}
                 phx-value-one={Map.get(record, hd(@primary_key))}
                 phx-value-two={Map.get(record, hd(tl(@primary_key)))} />
        </div>

        {#for column <- @columns}
          <GridPresenter presenter={column[:presenter]}
                         {=record}
                         field={column.field}
                         type={column.type}
                         {=index}
                         {=@model}
                         dye={dyed?(record, assigns)}/>
        {/for}
      {/for}
    </div>
    """
  end
end
