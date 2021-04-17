defmodule PanWeb.Surface.Admin.AssociationLink do
  use Surface.Component
  alias Surface.Components.LiveRedirect
  alias PanWeb.Router.Helpers, as: Routes

  prop(for, :map, required: true)
  prop(record, :map, required: true)

  def present(assigns) do
    link_title =
      assigns.for.field
      |> Atom.to_string
      |> String.replace("_", " ")
      |> String.capitalize

    case assigns.for do
      %Ecto.Association.BelongsTo{} ->
        if Map.get(assigns.record, assigns.for.owner_key) do
          Routes.databrowser_path(
              assigns.socket,
              :show,
              Phoenix.Naming.resource_name(assigns.for.related),
              Map.get(assigns.record, assigns.for.owner_key)
            )
            |> redirect(assigns, link_title)
        else
          "∅ " <> Phoenix.Naming.resource_name(assigns.for.related)
        end

      %Ecto.Association.Has{} ->
        Routes.databrowser_path(
          assigns.socket,
          :has_many,
          Phoenix.Naming.resource_name(assigns.for.owner),
          assigns.record.id,
          assigns.for.field
        )
        |> redirect(assigns, link_title)

      %Ecto.Association.ManyToMany{} ->
        Routes.databrowser_path(
          assigns.socket,
          :many_to_many,
          Phoenix.Naming.resource_name(assigns.for.owner),
          assigns.record.id,
          assigns.for.field
        )
        |> redirect(assigns, link_title)

      _other ->
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
