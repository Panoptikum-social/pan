defmodule PanWeb.Live.Admin.Databrowser.HasMany do
  use Surface.LiveView, layout: {PanWeb.LayoutView, "live_admin.html"}
  alias PanWeb.Surface.Admin.Naming
  alias PanWeb.Surface.Admin.IndexTable
  alias Phoenix.HTML
  alias Phoenix.HTML.Tag

  def mount(
    %{"owner" => owner_string, "owner_id" => owner_id_string, "association" => association_name},
    _session,
    socket
  ) do

    association_atom = String.to_atom(association_name)
    owner_model =  Naming.model_from_resource(owner_string)
    owner_id = String.to_integer(owner_id_string)
    association = owner_model.__schema__(:association, association_atom)
    related_key = association.related_key

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

      owner_columns = Naming.index_fields(owner_model) || owner_model.__schema__(:fields)
      owner_cols =
        Enum.map(
          owner_columns,
          &%{
            field: &1,
            label: Naming.title_from_field(&1),
            type: Naming.type_of_field(owner_model, &1),
            searchable: true,
            sortable: true
          }
        )

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

  def module_name(model) do
    model
    |> to_string
    |> String.split(".")
    |> List.last
  end

  def render(assigns) do
    ~H"""
    <IndexTable id="owner_table"
          heading={{ module_name(@owner_model) }}
          model={{ @owner_model }}
          cols={{ @owner_cols }}
          search_filter={{ @owner_search_filter }}
          per_page=1
          navigation=false>
    </IndexTable>

    <IndexTable id="has_many_table"
          heading={{ raw(HTML.safe_to_string(Tag.content_tag(:span, "has many", class: "italic mr-2")) <>
                     Naming.model_in_plural(@model)) }}
          model={{ @model }}
          cols={{ @cols }}
          search_filter={{ @search_filter }}
          per_page=20>
    </IndexTable>
    """
  end
end
