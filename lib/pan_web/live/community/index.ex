defmodule PanWeb.Live.Community.Index do
  use PanWeb, :live_view
  alias PanWeb.Community
  alias PanWeb.Component.Panel

  def mount(_params, _session, socket) do
    communities =
      for community <- Community.all() do
        %{community: community, member_count: length(Community.personas(community.id))}
      end

    {:ok, assign(socket, communities: communities, page_title: "Communities")}
  end

  def render(assigns) do
    ~H"""
    <div class="m-4">
      <h1 class="text-3xl">Communities</h1>
      <p class="mt-2 text-gray-dark">
        Panoptikum's communities are curated groups of podcasts and podcasters around a
        shared theme, each with its own moderators and members.
      </p>

      <div class="grid md:grid-cols-2 xl:grid-cols-3 gap-4 mt-4">
        <Panel.render
          :for={%{community: community, member_count: member_count} <- @communities}
          purpose="episode"
        >
          <div class="p-4">
            <h2 class="text-xl font-semibold">
              <.link
                href={community_frontend_path(@socket, :show, community)}
                class="text-link hover:text-link-dark"
              >{community.title}</.link>
            </h2>
            <p :if={community.description} class="mt-2">{community.description}</p>
            <p class="mt-2 text-gray-dark">{member_count} members</p>
          </div>
        </Panel.render>
      </div>
    </div>
    """
  end
end
