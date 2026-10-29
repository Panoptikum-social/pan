defmodule PanWeb.Live.Community.Show do
  use PanWeb, :live_view
  on_mount PanWeb.Live.AssignUserAndAdmin

  alias PanWeb.Community

  alias PanWeb.Component.Panel
  alias PanWeb.Component.FollowButton
  alias PanWeb.Component.PersonaButton
  alias PanWeb.Component.UserButton
  alias PanWeb.Component.LinkButton
  alias PanWeb.Pad

  def mount(%{"id" => id}, session, socket) do
    socket = assign(socket, current_user_id: session["user_id"])

    case Community.find_by_id(id) do
      nil ->
        {:ok, assign(socket, error: "not_found")}

      community ->
        {:ok,
         socket
         |> assign(
           community: community,
           community_personas: Community.personas(community.id),
           page_title: community.title <> " (Community)"
         )
         |> assign_pads()}
    end
  end

  # pads are only shown to followers, and the form for a new one only to
  # followers who also moderate the community
  defp assign_pads(%{assigns: %{community: community, current_user_id: user_id}} = socket) do
    permissions = Pad.permissions(user_id, community.id)

    assign(socket,
      pad_permissions: permissions,
      pads: if(permissions.read, do: Pad.all_of_community(community.id), else: []),
      pad_form: to_form(Pad.changeset(%Pad{}), as: :pad)
    )
  end

  def handle_info({:follow_toggled, _following}, socket) do
    {:noreply, assign_pads(socket)}
  end

  def handle_event("create_pad", %{"pad" => params}, socket) do
    %{community: community, current_user_id: user_id} = socket.assigns

    if Pad.permissions(user_id, community.id).manage do
      case Pad.create(community.id, params) do
        {:ok, pad} ->
          {:noreply,
           push_navigate(socket,
             to: pad_frontend_path(socket, :show, community.id, pad.slug)
           )}

        {:error, changeset} ->
          {:noreply, assign(socket, pad_form: to_form(changeset, as: :pad))}
      end
    else
      {:noreply, assign_pads(socket)}
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
            href={safe_href(@community.website)}
            rel="me"
            target="_blank"
            class="underline hover:text-primary"
          >
            {@community.website}
          </.link>
          <span :if={!safe_uri?(@community.website)}>{@community.website}</span>
        </p>

        <p :if={@community.fediverse_address} class="mt-2 text-base-content/70">
          {@community.fediverse_address}
        </p>

        <div :if={@current_user_id} class="mt-4">
          <.live_component
            module={FollowButton}
            id="community_follow_button"
            current_user_id={@current_user_id}
            model={Community}
            instance={@community}
            notify_parent={true}
          />
        </div>

        <div :if={@pad_permissions.read} class="mt-4">
          <h3 class="text-lg font-semibold">Pads</h3>
          <p class="text-sm text-base-content/70 mt-1">
            Markdown documents that the followers of this community write together.
          </p>
          <ul :if={@pads != []} class="list-disc m-4">
            <li :for={pad <- @pads}>
              <.link
                navigate={pad_frontend_path(@socket, :show, @community.id, pad.slug)}
                class="underline hover:text-primary"
              >
                {pad.title}
              </.link>
              <span :if={pad.read_only} class="badge badge-sm badge-ghost ml-2">read only</span>
            </li>
          </ul>
          <p :if={@pads == []} class="my-2">No pads yet.</p>

          <.form
            :if={@pad_permissions.manage}
            for={@pad_form}
            id="new-pad-form"
            phx-submit="create_pad"
            class="flex items-start gap-2 mt-2"
          >
            <.input field={@pad_form[:title]} placeholder="Title of the new pad" />
            <.button class="btn btn-primary">New pad</.button>
          </.form>
        </div>

        <div class="mt-4 flex flex-col gap-3">
          <div class="flex items-center gap-3">
            <LinkButton.render
              to={category_frontend_path(@socket, :show, @community.category_id)}
              title="Browse podcasts"
              class="btn-outline btn-primary w-44 justify-center shrink-0"
            />
            <span>shows every podcast in this community.</span>
          </div>
          <div class="flex items-center gap-3">
            <LinkButton.render
              to={category_frontend_path(@socket, :latest_episodes, @community.category_id)}
              title="Latest episodes"
              class="btn-outline btn-primary w-44 justify-center shrink-0"
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
              class="btn-outline btn-primary w-44 justify-center shrink-0"
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
              class="m-2"
            />
          </div>
        </div>

        <div :if={@community_personas != []} class="mt-4">
          <h3 class="text-lg font-semibold">Members ({length(@community_personas)})</h3>
          <p class="text-sm text-base-content/70 mt-1">
            The people behind the podcasts in this community — hosts, co-hosts, producers, and
            other contributors.
          </p>
          <div class="grid sm:grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5 py-4">
            <PersonaButton.render
              :for={persona <- @community_personas}
              for={persona}
              class="m-2"
            />
          </div>
        </div>
      </div>
    </Panel.render>
    """
  end
end
