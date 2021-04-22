defmodule PanWeb.Live.Admin.Databrowser.ManyToMany do
  use Surface.LiveView, layout: {PanWeb.LayoutView, "live_admin.html"}
  alias PanWeb.Surface.Admin.Naming
  alias PanWeb.Surface.Admin.IndexGrid
  import Ecto.Query
  alias Pan.Repo

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
    association = owner.__schema__(:association, association_atom)
    join_keys = association.join_keys |> Keyword.keys()
    join_through = Naming.model_from_join_through(association.join_through)
    children_id_column = join_keys |> List.last()

    children_ids =
      from(join_through,
        where: ^[{List.first(join_keys), owner_id}],
        select: ^[children_id_column]
      )
      |> Repo.all()
      |> Enum.map(&Map.get(&1, children_id_column))

    model = association.related
    columns = Naming.index_fields(model) || model.__schema__(:fields)

    cols =
      Enum.map(
        columns,
        &%{
          field: &1,
          label: Naming.title_from_field(&1),
          type: Naming.type_of_field(model, &1),
          searchable: true,
          sortable: true
        }
      )

    {:ok,
     assign(socket,
       model: model,
       cols: cols,
       search_filter: {:id, children_ids}
     )}
  end

  def render(assigns) do
    ~H"""
    <IndexGrid id="many_to_many_table"
          heading={{ "Listing " <> Naming.model_in_plural(@model) }}
          model={{ @model }}
          cols={{ @cols }}
          search_filter={{ @search_filter }}>
    </IndexGrid>
    """
  end
end
