defmodule PanWeb.Live.Community.Show do
  use PanWeb, :live_view
  on_mount PanWeb.Live.AssignUserAndAdmin

  alias PanWeb.Community

  alias PanWeb.Component.Panel
  alias PanWeb.Component.FollowButton
  alias PanWeb.Component.PersonaButton
  alias PanWeb.Component.UserButton
  alias PanWeb.Component.LinkButton

  def mount(%{"id" => id}, session, socket) do
    socket = assign(socket, current_user_id: session["user_id"])

    case Community.find_by_id(id) do
      nil ->
        {:ok, assign(socket, error: "not_found")}

      community ->
        {:ok,
         assign(socket,
           community: community,
           community_personas: Community.personas(community.id),
           page_title: community.title <> " (Community)"
         )}
    end
  end

  def render(%{error: "not_found"} = assigns) do
    ~H"""
    <div class="m-12">
      A community with this id could not be found
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <Panel.render purpose="episode" heading={@community.title} class="m-4">
      <div aria-label="panel-body" class="p-4">
        <p :if={@community.description}>{@community.description}</p>

        <p :if={@community.website} class="mt-2">
          <.link
            href={@community.website}
            rel="me"
            target="_blank"
            class="text-link hover:text-link-dark"
          >
            {@community.website}
          </.link>
        </p>

        <p :if={@community.fediverse_address} class="mt-2 text-gray-dark">
          {@community.fediverse_address}
        </p>

        <div :if={@current_user_id} class="mt-4">
          <.live_component
            module={FollowButton}
            id="community_follow_button"
            current_user_id={@current_user_id}
            model={Community}
            instance={@community}
          />
        </div>

        <div :if={@community.moderators != []} class="mt-4">
          <h3 class="text-lg font-semibold">Moderators</h3>
          <div class="flex flex-wrap mt-2">
            <UserButton.render :for={moderator <- @community.moderators} for={moderator} />
          </div>
        </div>

        <div :if={@community_personas != []} class="mt-4">
          <h3 class="text-lg font-semibold">Members ({length(@community_personas)})</h3>
          <div class="flex flex-wrap mt-2">
            <PersonaButton.render :for={persona <- @community_personas} for={persona} class="m-1" />
          </div>
        </div>

        <p class="mt-4 leading-8">
          <LinkButton.render
            to={category_frontend_path(@socket, :show, @community.category_id)}
            title="Browse podcasts"
            class="btn-primary"
          />&nbsp;
          shows every podcast in this community.<br />
          <LinkButton.render
            to={category_frontend_path(@socket, :latest_episodes, @community.category_id)}
            title="Latest episodes"
            class="btn-primary"
          />&nbsp;
          gives you a timeline view starting with the most current episode from podcasts in this
          community.<br />
          <LinkButton.render
            to={category_frontend_path(@socket, :categorized, @community.category_id)}
            title="Categorized"
            class="btn-primary"
          />&nbsp;
          sorts the podcasts in this community by the other categories they are listed in.
        </p>
      </div>
    </Panel.render>
    """
  end
end
