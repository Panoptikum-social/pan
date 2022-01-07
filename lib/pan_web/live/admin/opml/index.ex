defmodule PanWeb.Live.Admin.Opml.Index do
  use Surface.LiveView,
    layout: {PanWeb.LayoutView, "live_admin.html"},
    container: {:div, class: "m-4"}

  on_mount PanWeb.Live.Admin.Auth

  alias PanWeb.{Opml, Endpoint}
  alias PanWeb.Surface.LinkButton
  import PanWeb.Router.Helpers

  def mount(_params, _session, socket) do
    socket = assign(socket, sort_by: :inserted_at, sort_order: :desc)

    {:ok, socket |> fetch(), temporary_assigns: [opmls: []]}
  end

  defp fetch(%{assigns: %{sort_by: sort_by, sort_order: sort_order}} = socket) do
    assign(socket, opmls: Opml.all_with_user(sort_by, sort_order))
  end

  def render(assigns) do
    ~F"""
    <h2 class="text-2xl">Listing opmls</h2>

    <table cellpadding="4" class="my-4">
      <thead>
        <tr>
          <th class="border border-gray-light">Id</th>
          <th class="border border-gray-light">User</th>
          <th class="border border-gray-light">Content type</th>
          <th class="border border-gray-light">Filename</th>
          <th class="border border-gray-light">inserted at</th>
          <th class="border border-gray-light">Path</th>
          <th class="border border-gray-light">Actions</th>
        </tr>
      </thead>
      <tbody>
        {#for opml <- @opmls}
          <tr class="odd:bg-white">
            <td class="border border-gray-light">{opml.id}</td>
            <td class="border border-gray-light">{opml.user.name}</td>
            <td class="border border-gray-light">{opml.content_type}</td>
            <td class="border border-gray-light">{opml.filename}</td>
            <td class="border border-gray-light"><nobr> {opml.inserted_at |> Timex.format!("{YYYY}-{0M}-{0D} {h24}:{m}:{s}")}</nobr></td>
            <td class="border border-gray-light">{opml.path}</td>
            <td class="border border-gray-light">
              <LinkButton title="Parse"
                          to={opml_path(Endpoint, :import, opml.id)}
                          class="border-primary-dark bg-primary hover:bg-primary-light text-white" />
              <LinkButton title="Show"
                          class="border-gray bg-white hover:bg-gray-light"
                          to={opml_path(Endpoint, :show, opml.id)} />
              <LinkButton title="Edit"
                          class="border-warning-dark bg-warning hover:bg-warning-light text-white"
                          to={opml_path(Endpoint, :edit, opml.id)} />
              <LinkButton title="Delete"
                          to={opml_path(Endpoint, :delete, opml.id)}
                          method={:delete}
                          class="border-danger-dark bg-danger hover:bg-danger-light text-white"
                          opts={[confirm: "Are you sure?"]} />
            </td>
          </tr>
        {/for}
      </tbody>
    </table>

    <LinkButton title="New opml"
                to={opml_path(Endpoint, :new)} />
    """
  end
end
