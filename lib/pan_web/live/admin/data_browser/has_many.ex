defmodule PanWeb.Live.Admin.Databrowser.HasMany do
  use Surface.LiveView, layout: {PanWeb.LayoutView, "live_admin.html"}
  alias PanWeb.Surface.Admin.Naming
  alias PanWeb.Surface.Admin.IndexGrid

  def mount(
        %{
          "owner" => owner_string,
          "owner_id" => owner_id_string,
          "association" => association_name
        },
        _session,
        socket
      ) do
    association_atom = String.to_atom(association_name)
    owner_model = Naming.model_from_resource(owner_string)
    owner_id = String.to_integer(owner_id_string)
    association = owner_model.__schema__(:association, association_atom)
    related_key = association.related_key
    model = association.related

    cols =
      (Naming.index_fields(model) || model.__schema__(:fields))
      |> Enum.map(&map_to_cols(model, &1))

    owner_cols =
      (Naming.index_fields(owner_model) || owner_model.__schema__(:fields))
      |> Enum.map(&map_to_cols(owner_model, &1))

    {:ok,
     assign(socket,
       owner_model: owner_model,
       owner_id: owner_id,
       model: model,
       cols: cols,
       owner_cols: owner_cols,
       search_filter: {related_key, owner_id},
       owner_search_filter: {:id, owner_id}
     )}
  end

  defp map_to_cols(model, column) do
    %{
      field: column,
      label: Naming.title_from_field(column),
      type: Naming.type_of_field(model, column),
      searchable: true,
      sortable: true
    }
  end

  def handle_info({:count, id: id, module: module}, socket) do
    send_update(module, id: id, count: :now)
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <IndexGrid id="owner_table"
          heading={{ Naming.module_without_namespace(@owner_model) }}
          model={{ @owner_model }}
          cols={{ @owner_cols }}
          search_filter={{ @owner_search_filter }}
          per_page=1
          buttons={{ [:show, :edit] }}>
    </IndexGrid>

    <IndexGrid id="has_many_table"
          heading={{ "Has Many " <> Naming.model_in_plural(@model) }}
          model={{ @model }}
          cols={{ @cols }}
          search_filter={{ @search_filter }}
          per_page=20
          buttons={{ [:show, :edit, :delete, :new, :pagination,
                      :number_of_records, :link, :assignment_filter, :search] }} >
    </IndexGrid>
    """
  end
end
