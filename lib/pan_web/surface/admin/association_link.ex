defmodule PanWeb.Surface.Admin.AssociationLink do
  use Surface.Component
  alias Surface.Components.LiveRedirect
  alias PanWeb.Router.Helpers, as: Routes

  prop(for, :map, required: true)
  prop(record, :map, required: true)

  def present(assigns) do
    link_title =
      assigns.for.field |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()

    case assigns.for.cardinality do
      :one ->
        IO.inspect assigns.for.owner_key
        to =
          Routes.databrowser_path(
            assigns.socket,
            :show,
            Phoenix.Naming.resource_name(assigns.for.related),
            Map.get(assigns.record, assigns.for.owner_key)
          )

        render_one(assigns, to, link_title)

      :many ->
        link_title
    end
  end

  def render_one(assigns, to, link_title) do
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
