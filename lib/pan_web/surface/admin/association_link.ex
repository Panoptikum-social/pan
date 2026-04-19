defmodule PanWeb.Surface.Admin.AssociationLink do
  use PanWeb, :html
  alias PanWeb.Router.Helpers, as: Routes
  alias PanWeb.Endpoint

  attr :for, :map, required: true
  attr :record, :map, required: true

  def present(assigns) do
    link_title =
      assigns.for.field
      |> Atom.to_string()
      |> String.replace("_", " ")
      |> String.capitalize()

    case assigns.for do
      %Ecto.Association.BelongsTo{} ->
        if Map.get(assigns.record, assigns.for.owner_key) do
          Routes.databrowser_path(
            Endpoint,
            :show,
            Phoenix.Naming.resource_name(assigns.for.related),
            Map.get(assigns.record, assigns.for.owner_key)
          )
          |> styled_live_redirect(assigns, link_title)
        else
          "∅ " <> Phoenix.Naming.resource_name(assigns.for.related)
        end

      %Ecto.Association.Has{} ->
        Routes.databrowser_path(
          Endpoint,
          :has_many,
          Phoenix.Naming.resource_name(assigns.for.owner),
          assigns.record.id,
          assigns.for.field
        )
        |> styled_live_redirect(assigns, link_title)

      %Ecto.Association.ManyToMany{} ->
        Routes.databrowser_path(
          Endpoint,
          :many_to_many,
          Phoenix.Naming.resource_name(assigns.for.owner),
          assigns.record.id,
          assigns.for.field
        )
        |> styled_live_redirect(assigns, link_title)

      _other ->
        link_title
    end
  end

  def styled_live_redirect(to, assigns, link_title) do
    assigns = assigns |> assign(:to, to) |> assign(:link_title, link_title)

    ~H"""
    <.link navigate={@to}
           class="text-link hover:text-link-dark text-medium underline">
      {@link_title}
    </.link>
    """
  end

  def render(assigns) do
    ~H"""
    {present(assigns)}
    """
  end
end
