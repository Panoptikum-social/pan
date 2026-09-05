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
            :if={safe_uri?(@community.website)}
            href={@community.website}
            rel="me"
            target="_blank"
            class="text-link hover:text-link-dark"
          >
            {@community.website}
          </.link>
          <span :if={!safe_uri?(@community.website)}>{@community.website}</span>
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

        <div class="mt-4 flex flex-col gap-3">
          <div class="flex items-center gap-3">
            <LinkButton.render
              to={category_frontend_path(@socket, :show, @community.category_id)}
              title="Browse podcasts"
              class="btn-primary w-44 justify-center shrink-0"
            />
            <span>shows every podcast in this community.</span>
          </div>
          <div class="flex items-center gap-3">
            <LinkButton.render
              to={category_frontend_path(@socket, :latest_episodes, @community.category_id)}
              title="Latest episodes"
              class="btn-primary w-44 justify-center shrink-0"
            />
            <span>
              gives you a timeline view starting with the most current episode from podcasts in
              this community.
            </span>
          </div>
          <div class="flex items-center gap-3">
            <LinkButton.render
              to={category_frontend_path(@socket, :categorized, @community.category_id)}
              title="Categorized"
              class="btn-primary w-44 justify-center shrink-0"
            />
            <span>sorts the podcasts in this community by the other categories they are listed in.</span>
          </div>
        </div>

        <div :if={@community.moderators != []} class="mt-4">
          <h3 class="text-lg font-semibold">Moderators</h3>
          <div class="grid sm:grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5 py-4">
            <UserButton.render
              :for={moderator <- @community.moderators}
              for={moderator}
              class="m-2 h-auto min-h-10 py-2 whitespace-normal text-center leading-snug"
            />
          </div>
        </div>

        <div :if={@community_personas != []} class="mt-4">
          <h3 class="text-lg font-semibold">Members ({length(@community_personas)})</h3>
          <p class="text-sm text-gray-dark mt-1">
            The people behind the podcasts in this community — hosts, co-hosts, producers, and
            other contributors.
          </p>
          <div class="grid sm:grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5 py-4">
            <PersonaButton.render
              :for={persona <- @community_personas}
              for={persona}
              class="m-2 h-auto min-h-10 py-2 whitespace-normal text-center leading-snug"
            />
          </div>
        </div>
      </div>
    </Panel.render>
    """
  end
end
