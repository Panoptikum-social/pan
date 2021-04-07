defmodule PanWeb.Surface.Admin.AssociationLink do
  use Surface.Component
  alias Surface.Components.LiveRedirect
  alias PanWeb.Router.Helpers, as: Routes

  prop(for, :map, required: true)
  prop(record, :map, required: true)

  def present(assigns) do
    link_title =
      assigns.for.field
      |> Atom.to_string()
      |> String.replace("_", " ")
      |> String.capitalize()

    case assigns.for do
      %Ecto.Association.BelongsTo{} ->
        Routes.databrowser_path(
          assigns.socket,
          :show,
          Phoenix.Naming.resource_name(assigns.for.related),
          Map.get(assigns.record, assigns.for.owner_key)
        )
        |> redirect(assigns, link_title)

      %Ecto.Association.Has{} ->
        Routes.databrowser_path(
          assigns.socket,
          :has_many,
          assigns.for.related_key,
          assigns.record.id,
          Phoenix.Naming.resource_name(assigns.for.related)
        )
        |> redirect(assigns, link_title)

      other ->
        IO.inspect other
        link_title
    end
  end

  def redirect(to, assigns, link_title) do
    ~H"""
    <LiveRedirect to={{ to }}
                      class="text-link hover:text-link-dark text-medium underline"
                      label={{ link_title }} />
    """
  end

  def render(assigns) do
    ~H"""
    {{ present(assigns) }}
    """
  end
end

%Ecto.Association.Has{
  cardinality: :many,
  defaults: [],
  field: :episodes,
  on_cast: nil,
  on_delete: :delete_all,
  on_replace: :raise,
  ordered: false,
  owner: PanWeb.Podcast,
  owner_key: :id,
  queryable: PanWeb.Episode,
  related: PanWeb.Episode,
  related_key: :podcast_id,
  relationship: :child,
  unique: true,
  where: []
}
