defmodule PanWeb.Live.Admin.Databrowser.DbIndex do
  use PanWeb, :admin_live_view

  alias PanWeb.Admin.Naming
  require Integer

  def mount(%{"resource" => resource}, _session, socket) do
    model = Naming.model_from_resource(resource)
    {:ok, assign(socket, resource: resource, model: model)}
  end

  def get_indices(assigns) do
    table_name = Naming.table_name(assigns.model)

    response =
      Ecto.Adapters.SQL.query(
        Pan.Repo,
        "SELECT indexname, indexdef FROM pg_indexes WHERE tablename = '#{table_name}' ORDER BY indexname;"
      )

    {:ok, %Postgrex.Result{rows: indices}} = response
    indices
  end

  def render(assigns) do
    ~H"""
    <div class="m-2 border border-gray rounded">
      <h1 class="p-1 border-b border-gray text-center bg-linear-to-r from-gray-light via-gray-lighter to-gray-light font-mono">
        Database Indices for Resource
        <span class="italic">{Naming.module_without_namespace(@model)}</span>
      </h1>
      <div class="grid mb-1"
           style="grid-template-columns: max-content 1fr;">
          <div class="px-2 font-semibold py-0.5 text-gray-darker italic text-right">
            Index Name
          </div>
          <div class="w-full font-semibold pl-4 pr-2 py-0.5">
            Index Definition
          </div>
        <%= for {[name, definition], index} <- get_indices(assigns) |> Enum.with_index do %>
          <div class={["px-2 py-0.5 text-gray-darker italic text-right",
                       if(Integer.is_even(index), do: "bg-white"),
                       if(Integer.is_odd(index), do: "bg-gray-lightest"),
                       if(index > 0, do: "border-t-2 border-gray-lighter")]}>
            {name}
          </div>
          <div class={["w-full pl-4 pr-2 py-0.5",
                       if(Integer.is_even(index), do: "bg-white"),
                       if(Integer.is_odd(index), do: "bg-gray-lightest"),
                       if(index > 0, do: "border-t-2 border-gray-lighter")]}>
            {definition}
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
