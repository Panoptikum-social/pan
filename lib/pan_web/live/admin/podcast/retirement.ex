defmodule PanWeb.Live.Admin.Podcast.Retirement do
  use Surface.LiveView,
    layout: {PanWeb.LayoutView, "live_admin.html"},
    container: {:div, class: "m-4"}

  on_mount PanWeb.Live.Admin.Auth

  alias PanWeb.{Endpoint, Podcast}
  alias PanWeb.Surface.LinkButton
  import PanWeb.Router.Helpers

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       candidates: Podcast.retirement_candidates(),
       retired: Podcast.retired()
     )}
  end

  def render(assigns) do
    ~F"""
    <h2 class="text-2xl">Candidates for Retirement</h2>

    <table cellpadding="4" class="table table-striped table-condensed table-bordered">
      <thead>
        <tr>
          <th class="border border-gray-light">ID</th>
          <th class="border border-gray-light">Title</th>
          <th class="border border-gray-light">Last build date</th>
          <th class="border border-gray-light">Latest episode publishing date</th>
          <th class="border border-gray-light"></th>
        </tr>
      </thead>
      <tbody>
        {#for podcast <- @candidates}
          <tr>
            <td class="border border-gray-light">{podcast.id}</td>
            <td class="border border-gray-light">{podcast.title}</td>
            <td class="border border-gray-light">{podcast.last_build_date}</td>
            <td class="border border-gray-light">{podcast.latest_episode_publishing_date}</td>

            <td class="border border-gray-light">
              <nobr>
                <LinkButton title="Show"
                            to={databrowser_path(Endpoint, :show, "podcast", podcast.id)}
                            class="bg-default hover:bg-default-lighter text-black border-gray" />
                <LinkButton title="Edit"
                            to={databrowser_path(Endpoint, :edit, "podcast", podcast.id)}
                            class="bg-warning hover:bg-warning-lighter text-black border-gray" />
                <LinkButton title="Retire"
                            to={podcast_path(Endpoint, :retire, podcast.id)}
                            class="bg-info hover:bg-info-lighter text-black border-gray" />
              </nobr>
            </td>
          </tr>
        {/for}
      </tbody>
    </table>

    <h2 class="mt-4 text-2xl">Retired Podcasts</h2>

    <table cellpadding="4" class="table table-striped table-condensed table-bordered">
      <thead>
        <tr>
          <th class="border border-gray-light">ID</th>
          <th class="border border-gray-light">Title</th>
          <th class="border border-gray-light"></th>
        </tr>
      </thead>
      <tbody>
        {#for podcast <- @retired}
          <tr>
            <td class="border border-gray-light">{podcast.id}</td>
            <td class="border border-gray-light">{podcast.title}</td>
            <td class="border border-gray-light">
              <nobr>
                <LinkButton title="Show"
                            to={databrowser_path(Endpoint, :show, "podcast", podcast.id)}
                            class="bg-default hover:bg-default-lighter text-black border-gray" />
                <LinkButton title="Edit"
                            to={databrowser_path(Endpoint, :edit, "podcast", podcast.id)}
                            class="bg-warning hover:bg-warning-lighter text-black border-gray" />
              </nobr>
            </td>
          </tr>
        {/for}
      </tbody>
    </table>
    """
  end
end
