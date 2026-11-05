defmodule PanWeb.Live.Persona.Show do
  use PanWeb, :live_view
  import PanWeb.Router.Helpers
  on_mount PanWeb.Live.AssignUserAndAdmin
  alias PanWeb.{Endpoint, Persona, Delegation, Gig, Image, Engagement, User}
  alias PanWeb.Component.Panel
  alias PanWeb.Component.Pill
  alias PanWeb.Component.FollowButton
  alias PanWeb.Component.LikeButton
  alias PanWeb.Component.EpisodeButton
  alias PanWeb.Component.PodcastButton

  def mount(%{"pid" => pid}, _session, socket) do
    current_user =
      socket.assigns.current_user_id && User.get_by_id(socket.assigns.current_user_id)

    persona = Persona.get_by_pid(pid)

    if persona do
      delegator_ids = Delegation.get_by_delegate_id(persona.id)
      persona_ids = [persona.id | delegator_ids]
      engagements = Engagement.get_by_persona_ids(persona_ids)
      persona_thumbnail = Image.get_by_persona_id(persona.id) || %{}

      if persona.redirect_id do
        persona = Persona.get_by_id(persona.redirect_id)
        redirect(socket, to: persona_frontend_path(Endpoint, :persona, persona.pid))
      end

      socket =
        assign(socket,
          current_user: current_user,
          persona: persona,
          persona_ids: persona_ids,
          gigs_page: 1,
          gigs_per_page: 10,
          persona_thumbnail: persona_thumbnail,
          engagements: engagements,
          page_title: dgettext("frontend", "%{name} (Persona)", name: persona.name || "Persona")
        )
        |> fetch_gigs

      {:ok, socket}
    else
      {:ok, assign(socket, not_found: true)}
    end
  end

  def mount(:not_mounted_at_router, %{"_csrf_token" => _token}, socket) do
    {:ok, assign(socket, wrong_token: true)}
  end

  defp fetch_gigs(
         %{
           assigns: %{
             persona_ids: persona_ids,
             gigs_page: gigs_page,
             gigs_per_page: gigs_per_page
           }
         } = socket
       ) do
    gigs = Gig.get_by_persona_ids(persona_ids, gigs_page, gigs_per_page)
    grouped = Gig.grouped_gigs(gigs)

    rows =
      grouped
      |> Map.keys()
      |> Enum.sort_by(&Date.to_erl(&1.publishing_date), :desc)
      |> Enum.map(fn episode -> %{id: episode.id, episode: episode, gigs: grouped[episode]} end)

    socket
    |> stream(:gig_rows, rows, reset: false)
    |> assign(
      has_gigs: rows != [] || Map.get(socket.assigns, :has_gigs, false),
      has_more_gigs: length(gigs) == gigs_per_page
    )
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, assign(socket, gigs_page: assigns.gigs_page + 1) |> fetch_gigs()}
  end

  def render(%{not_found: true} = assigns) do
    ~H"""
    <div class="m-4">
      {dgettext("frontend", "We don't know a persona with that name.")}
    </div>
    """
  end

  def render(%{wrong_token: true} = assigns) do
    ~H"""
    <div class="m-4">
      {dgettext("frontend", "The crawler sent the wrong token.")}
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="m-4 flex flex-col md:flex-row space-y-4 md:space-y-0 md:space-x-4">
      <Panel.render heading={@persona.name} purpose="user">
        <div class="flex flex-wrap m-4">
          <table class="grow basis-64">
            <tr>
              <td class="px-4 text-right font-semibold">{dgettext("frontend", "PanoptikumID")}</td>
              <td>{@persona.pid}</td>
            </tr>
            <tr>
              <td class="px-4 text-right font-semibold">{dgettext("frontend", "Permalink (URI)")}</td>
              <td>{Endpoint.url()}/{@persona.pid}</td>
            </tr>
            <tr>
              <td class="px-4 text-right font-semibold">{dgettext("frontend", "Name")}</td>
              <td>{@persona.name}</td>
            </tr>
            <tr :if={@persona.uri}>
              <td class="px-4 text-right font-semibold">{dgettext("frontend", "Uri")}</td>
              <td>
                <.link
                  :if={safe_uri?(@persona.uri)}
                  href={safe_href(@persona.uri)}
                  rel="me"
                  target="_blank"
                  class="underline hover:text-primary"
                >{@persona.uri}</.link>
                <span :if={!safe_uri?(@persona.uri)}>{@persona.uri}</span>
              </td>
            </tr>
            <tr>
              <td class="px-4 text-right font-semibold">{dgettext("frontend", "ID")}</td>
              <td>{@persona.id}</td>
            </tr>
          </table>

          <div class="flex-none rounded shadow m-auto md:mx-4 my-4">
            <img
              :if={Map.has_key?(@persona_thumbnail, :path)}
              src={"https://panoptikum.social#{@persona_thumbnail.path}#{@persona_thumbnail.filename}"}
              alt={@persona.image_title}
              id="photo"
              width="150"
              height="150"
            />
            <img
              :if={!Map.has_key?(@persona_thumbnail, :path)}
              src="/images/missing-persona.png"
              alt={dgettext("frontend", "missing image")}
              width="150"
              height="150"
            />
          </div>
        </div>

        <p :if={@current_user_id} class="m-4">
          <.live_component
            module={LikeButton}
            id="like_button"
            current_user_id={@current_user_id}
            model={Persona}
            instance={@persona}
          />
          <.live_component
            module={FollowButton}
            id="follow_button"
            current_user_id={@current_user_id}
            model={Persona}
            instance={@persona}
          />
        </p>
      </Panel.render>

      <div>
        <Panel.render
          :if={!@current_user}
          heading={dgettext("frontend", "Claiming not available")}
          purpose="persona"
        >
          <p class="m-4">
            {dgettext("frontend", "You can only claim personas, if you are logged in.")}
          </p>
        </Panel.render>

        <Panel.render
          :if={@current_user && !@current_user.podcaster}
          heading={dgettext("frontend", "Claiming not available")}
          purpose="persona"
        >
          <p class="m-4">
            {dgettext("frontend", "You didn't say you are a podcaster in")}
            <.link
              href={user_frontend_path(Endpoint, :my_profile)}
              class="underline hover:text-primary"
            >{dgettext("frontend", "My Profile")}</.link>
            {dgettext("frontend", "yet.")}
          </p>
        </Panel.render>

        <Panel.render
          :if={@current_user && @current_user.podcaster && !@current_user.email_verified}
          heading={dgettext("frontend", "Claiming not available")}
          purpose="persona"
        >
          <p class="m-4">
            {dgettext(
              "frontend",
              "You didn't verify your email address by clicking on the verification link in the email sent to you after login."
            )}
          </p>
        </Panel.render>

        <Panel.render
          :if={
            @current_user && @current_user.podcaster && @current_user.email_verified &&
              !@persona.email
          }
          heading={dgettext("frontend", "Claiming")}
          purpose="persona"
        >
          <div class="m-4">
            <p>
              {dgettext(
                "frontend",
                "Please take the time to read the text on the following screen carefully."
              )}
            </p>
            <p>
              <.link
                href={persona_frontend_path(Endpoint, :warning, @persona)}
                class="btn btn-warning btn-sm mt-4"
              >
                {dgettext("frontend", "Start claiming process")}
              </.link>
            </p>
          </div>
        </Panel.render>

        <Panel.render
          :if={
            @current_user && @current_user.podcaster && @current_user.email_verified &&
              @persona.email
          }
          heading={dgettext("frontend", "Claiming")}
          purpose="persona"
        >
          <p
            :if={
              Pan.Repo.get_by(PanWeb.Manifestation,
                persona_id: @persona.id,
                user_id: @current_user.id
              )
            }
            class="m-4"
          >
            {dgettext("frontend", "You have claimed this persona already.")}
          </p>
          <div
            :if={
              !Pan.Repo.get_by(PanWeb.Manifestation,
                persona_id: @persona.id,
                user_id: @current_user.id
              )
            }
            class="m-4"
          >
            <p>
              {dgettext(
                "frontend",
                "You can send an email to the owner of this persona and ask for permission to add you as a manifestation of this persona."
              )}<br />
              {dgettext(
                "frontend",
                "Your name, username and email address will be sent alongside in the email to give the owner a chance to get in contact with you."
              )}
            </p>

            <.link
              href={persona_frontend_path(Endpoint, :claim, @persona)}
              method="post"
              data-confirm={dgettext("frontend", "Are you sure?")}
              class="btn btn-warning btn-sm mt-4"
            >
              {dgettext("frontend", "Claim")}
            </.link>
          </div>
        </Panel.render>
      </div>
    </div>

    <Panel.render
      :if={@persona.description || @persona.long_description}
      heading={@persona.description}
      purpose="info"
      class="m-4 max-w-7xl"
    >
      <div class="m-4 prose max-w-none prose-sm prose-green">
        {@persona.long_description |> markdown}
      </div>
    </Panel.render>

    <Panel.render
      :if={false && @persona.fediverse_address}
      heading={
        dgettext("frontend", "%{address} in the Fediverse", address: @persona.fediverse_address)
      }
      purpose="gig"
      class="m-4 max-w-7xl"
    >
      {Pan.ActivityPub.View.widget(@persona.fediverse_address)}
    </Panel.render>

    <Panel.render
      :if={@engagements != []}
      heading={dgettext("frontend", "Engagements, %{name} has entered", name: @persona.name)}
      purpose="engagement"
      class="m-4"
    >
      <table class="m-4">
        <thead>
          <tr>
            <th>{dgettext("frontend", "Podcast")}</th>
            <th>{dgettext("frontend", "Role")}</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={{podcast, engagements} <- Enum.group_by(@engagements, &Map.get(&1, :podcast))}>
            <td class="px-2"><PodcastButton.render for={podcast} /></td>
            <td class="px-2">
              <Pill.render :for={engagement <- Enum.uniq_by(engagements, & &1.role)} type="success">
                {engagement.role}
              </Pill.render>
            </td>
          </tr>
        </tbody>
      </table>
    </Panel.render>

    <Panel.render
      :if={@has_gigs}
      heading={dgettext("frontend", "Gigs, %{name} has been engaged in", name: @persona.name)}
      purpose="gig"
      class="m-4"
    >
      <table class="m-4">
        <thead>
          <tr class="flex flex-col sm:table-row">
            <th>{dgettext("frontend", "Date")}</th>
            <th>{dgettext("frontend", "Podcast")}</th>
            <th>{dgettext("frontend", "Episode")}</th>
            <th>{dgettext("frontend", "Role")}</th>
          </tr>
        </thead>
        <tbody phx-update="stream" id="gigs-table-body">
          <tr
            :for={{dom_id, row} <- @streams.gig_rows}
            id={dom_id}
            class="flex flex-col sm:table-row odd:bg-base-200"
          >
            <td align="center" class="px-2 py-2">
              {row.episode.publishing_date && Calendar.strftime(row.episode.publishing_date, "%x")}
            </td>
            <td class="px-2 py-2"><PodcastButton.render for={row.episode.podcast} /></td>
            <td class="px-2 py-2"><EpisodeButton.render for={row.episode} /></td>
            <td class="px-2 py-2">
              <Pill.render
                :for={gig <- Enum.uniq_by(row.gigs, & &1.role)}
                id={"gig-#{gig.id}"}
                type="success"
              >
                {gig.role}
              </Pill.render>
            </td>
          </tr>
        </tbody>
      </table>
      <div
        :if={@has_more_gigs}
        id="infinite-scroll"
        class="h-4"
        phx-hook="InfiniteScroll"
        data-page={@gigs_page}
      >
      </div>
    </Panel.render>
    """
  end
end
