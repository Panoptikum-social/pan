defmodule PanWeb.Live.Admin.Databrowser.ManyToMany do
  use Surface.LiveView, layout: {PanWeb.LayoutView, "live_admin.html"}
  alias PanWeb.Surface.Admin.Naming
  alias PanWeb.Surface.Admin.IndexGrid
  import Ecto.Query
  alias Pan.Repo
  alias PanWeb.Router.Helpers, as: Routes

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
    owner = Naming.model_from_resource(owner_string)
    owner_id = String.to_integer(owner_id_string)
    owner_model = Naming.model_from_resource(owner_string)
    association = owner.__schema__(:association, association_atom)
    join_keys = association.join_keys |> Keyword.keys()
    join_through = association.join_through
    join_through_model = Naming.model_from_join_through(association.join_through)
    children_id_column = join_keys |> List.last()

    children_ids =
      from(join_through,
        where: ^[{hd(join_keys), owner_id}],
        select: ^[children_id_column]
      )
      |> Repo.all()
      |> Enum.map(&Map.get(&1, children_id_column))

    model = association.related

    cols =
      (Naming.index_fields(model) || model.__schema__(:fields))
      |> Enum.map(&map_to_cols(model, &1))

    join_through_cols =
      (Naming.index_fields(join_through_model) || join_through_model.__schema__(:fields))
      |> Enum.map(&map_to_cols(join_through_model, &1))

    owner_cols =
      (Naming.index_fields(owner_model) || owner_model.__schema__(:fields))
      |> Enum.map(&map_to_cols(owner_model, &1))

    {:ok,
     assign(socket,
       owner_model: owner_model,
       owner_cols: owner_cols,
       join_through: join_through,
       join_keys: join_keys,
       join_through_model: join_through_model,
       join_through_cols: join_through_cols,
       model: model,
       cols: cols,
       owner_search_filter: {:id, owner_id},
       join_search_filter: {elem(hd(association.join_keys), 0), owner_id},
       search_filter: {:id, children_ids}
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

  def handle_info({:associate_to, related_id}, socket) do
    {:id, owner_id} = socket.assigns.owner_search_filter

    new_association_path =
      Routes.databrowser_path(
        socket,
        :new_association,
        socket.assigns.join_through,
        hd(socket.assigns.join_keys),
        owner_id,
        hd(tl(socket.assigns.join_keys)),
        related_id
      )

    {:noreply, push_redirect(socket, to: new_association_path)}
  end

  def handle_info({:count, id: id, module: module}, socket) do
    send_update(module, id: id, count: :now)
    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
    <IndexGrid id="owner_table"
               color_class="from-pink-rose-light via-pink-rose to-pink-rose-light"
               heading={Naming.module_without_namespace(@owner_model)}
               model={@owner_model}
               cols={@owner_cols}
               search_filter={@owner_search_filter}
               per_page={1}
               buttons={[:show, :edit]}>
    </IndexGrid>

    <IndexGrid id="join_through_table"
               class="mt-8"
               color_class="from-lavender-light via-lavender to-lavender-light"
               heading={"Join Through " <> Naming.model_in_plural(@join_through_model)}
               model={@join_through_model}
               cols={@join_through_cols}
               search_filter={@join_search_filter}
               buttons={[:show, :edit, :delete, :new, :pagination,
                           :number_of_records, :search]}>
    </IndexGrid>

    <IndexGrid id="many_to_many_table"
               class="mt-8"
               color_class="from-mint-light via-mint to-mint-light"
               heading={"Many To Many " <> Naming.model_in_plural(@model)}
               model={@model}
               cols={@cols}
               search_filter={@search_filter}
               buttons={[:show, :edit, :pagination, :number_of_records,
                           :new_mediating, :assignment_filter, :search]}>
    </IndexGrid>
    """
  end
end
