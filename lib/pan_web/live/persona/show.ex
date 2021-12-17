defmodule PanWeb.Live.Persona.Show do
  use Surface.LiveView
  import PanWeb.Router.Helpers
  on_mount PanWeb.Live.AssignUserAndAdmin
  alias PanWeb.{Endpoint, Persona, Delegation, Gig, Image, Engagement, Message, User}
  alias PanWeb.Surface.{PodcastButton, EpisodeButton, Pill, Icon, Panel}
  alias PanWeb.Live.Persona.{FollowOrUnfollowButton, LikeOrUnlikeButton}

  def mount(%{"pid" => pid}, _session, socket) do
    current_user = socket.assigns.current_user_id && User.get_by_id(socket.assigns.current_user_id)
    persona = Persona.get_by_pid(pid)

    unless persona do
      {:ok, assign(socket, not_found: true)}
    else
      delegator_ids = Delegation.get_by_delegate_id(persona.id)
      persona_ids = [persona.id | delegator_ids]
      engagements = Engagement.get_by_persona_ids(persona_ids)
      persona_thumbnail = Image.get_by_persona_id(persona.id)
      messages_count = Message.count_by_persona_id(persona.id)

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
          messages_page: 1,
          messages_per_page: 10,
          messages_count: messages_count,
          persona_thumbnail: persona_thumbnail,
          engagements: engagements
        )
        |> fetch_gigs
        |> fetch_messages

      {:ok, socket, temporary_assigns: [gigs: [], grouped_gigs: []]}
    end
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
    assign(socket, gigs: gigs, grouped_gigs: Gig.grouped_gigs(gigs))
  end

  defp fetch_messages(
         %{
           assigns: %{
             persona_ids: persona_ids,
             messages_page: messages_page,
             messages_per_page: messages_per_page
           }
         } = socket
       ) do
    assign(socket,
      messages: Message.get_by_persona_ids(persona_ids, messages_page, messages_per_page)
    )
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, assign(socket, gigs_page: assigns.gigs_page + 1) |> fetch_gigs()}
  end

  def handle_event("load-more-messages", _, %{assigns: assigns} = socket) do
    {:noreply, assign(socket, messages_page: assigns.messages_page + 1) |> fetch_messages()}
  end

  defp markdown(content) do
    if content do
      content
      |> Earmark.as_html!()
      |> HtmlSanitizeEx.html5()
      |> raw()
    end
  end

  defp ordered_episodes(grouped_gigs) do
    grouped_gigs
    |> Map.keys()
    |> Enum.sort_by(&Date.to_erl(&1.publishing_date))
    |> Enum.reverse()
  end

  defp format_date(date) do
    if date do
      Timex.to_date(date)
      |> Timex.format!("%e.%m.%Y", :strftime)
    end
  end

  defp format_datetime(date_time) do
    Timex.to_date(date_time)
    |> Timex.format!("%e.%m.%Y", :strftime)
  end

  def render(%{not_found: true} = assigns) do
    ~F"""
    <div class="m-4">
      We don't know a persona with that name.
    </div>
    """
  end

  def render(assigns) do
    ~F"""
    <div class="m-4 flex space-x-4">
      <Panel heading={@persona.name}
             purpose="user">
        <div class="flex m-4">
          <table>
            <tr>
              <td class="px-4 text-right font-semibold">Panoptikum-ID</td>
              <td>{@persona.pid}</td>
            </tr>
            <tr>
              <td class="px-4 text-right font-semibold">Permalink (URI)</td>
              <td>{Endpoint.url}/{@persona.pid}</td>
            </tr>
            <tr>
              <td class="px-4 text-right font-semibold">Name</td>
              <td>{@persona.name}</td>
            </tr>
            <tr>
              {#if @persona.uri}
                <td class="px-4 text-right font-semibold">Uri</td>
                <td>{ @persona.uri}</td>
              {/if}
            </tr>
            <tr>
              <td class="px-4 text-right font-semibold">Business Cards</td>
              <td>
                <a href={persona_frontend_url(Endpoint, :business_card, @persona)}>
                  <Icon name="credit-card-heroicons-outline"/> Show
                </a>
              </td>
            </tr>
          </table>

          <img :if={@persona_thumbnail}
                alt={@persona.image_title}
                class="rounded shadow ml-4"
                id="photo" />
          <img :if={!@persona_thumbnail}
                src="/images/missing-persona.png"
                alt="missing image"
                width="150"
                class="rounded shadow ml-4" />
        </div>

        <p :if={@current_user_id}
           class="m-4">
          <LikeOrUnlikeButton id="like_or_unlike_button"
                              persona={@persona}
                              current_user_id={@current_user_id} />
          <FollowOrUnfollowButton id="follow_or_unfollow_button"
                                  persona={@persona}
                                  current_user_id={@current_user_id} />
        </p>
      </Panel>

      <div>
        {#if !@current_user}
          <Panel heading="Claiming not available" purpose="persona">
            <p class="m-4">You can only claim personas, if you are logged in.</p>
          </Panel>

        {#elseif !@current_user.podcaster}
          <Panel heading="Claiming not available" purpose="persona">
            <p class="m-4">You didn't say you are a podcaster in
              <a href={user_frontend_path(Endpoint, :my_profile)}
                 class="btn btn-sm btn-default">My Profile</a> yet.</p>
          </Panel>

        {#elseif !@current_user.email_confirmed}
          <Panel heading="Claiming not available" purpose="persona">
            <p class="m-4">You didn't confirm your email address by clicking on the
                           confirmation link in the email sent to you after login.</p>
          </Panel>

        {#elseif !@persona.email}
          <Panel heading="Claiming" purpose="persona">
            <div class="m-4">
              <p>Please take the time to read the text on the following screen carefully.</p>
              <p>
                <a href={persona_frontend_path(Endpoint, :warning, @persona)}
                  class="mt-4 border border-solid inline-block shadow py-1 px-2 rounded text-sm bg-warning hover:bg-warning-light">
                  Start claiming process
                </a>
              </p>
            </div>
          </Panel>

        {#else}
          <Panel heading="Claiming" purpose="persona">

            {#if Pan.Repo.get_by(PanWeb.Manifestation, persona_id: @persona.id,
                                                      user_id: @current_user.id)}
              <p class="m-4">You have claimed this persona already.</p>
            {#else}
              <div class="m-4">
                <p>You can send an email to the owner of this persona and ask her for permission
                  to add you as a manifestation of this persona.<br/>
                  Your name, username and email address will be sent alongside in the email
                  to give the owner a chance to get in contact with you.</p>

                <a href={persona_frontend_path(Endpoint, :claim, @persona)}
                   class="mt-4 border border-solid inline-block shadow py-1 px-2 rounded text-sm bg-warning hover:bg-warning-light",
                   method="post"
                   data={[confirm: "Are you sure?"]} >Claim</a>

              </div>
            {/if}
          </Panel>
        {/if}
      </div>
    </div>

    <Panel :if={@persona.description || @persona.long_description}
           heading={@persona.description}
           purpose="persona"
           class="m-4 max-w-screen-xl">
        <div class="m-4 prose max-w-none prose-sm prose-green">{@persona.long_description |> markdown}</div>
    </Panel>

    <Panel :if={@messages != []}
           heading={"Messages created by #{@persona.name}"}
           purpose="message"
           class="m-4">
       <table class="m-4">
         <tbody phx-update="append" id="message-table-body">
           {#for message <- @messages}
             <tr id={"message-#{message.id}"}>
               <td class={"bg-#{message.type} px-2"}>
                 <i>{message.creator && message.creator.name || message.persona.name}</i>
               </td>
               <td class="px-2">{raw message.content}</td>
               <td class="px-2 text-right">{message.inserted_at |> format_datetime}</td>
             </tr>
           {/for}
         </tbody>
       </table>
    </Panel>
    <button :if={@messages_page * @messages_per_page < @messages_count}
            :on-click="load-more-messages"
            class="border border-solid inline-block shadow m-4 py-1 px-2 rounded text-sm bg-info
                  hover:bg-info-light text-white border-gray-dark">
      Load more
    </button>

    <Panel :if={@engagements != []}
           heading={"Engagements, #{@persona.name} has entered"}
           purpose="engagement"
           class="m-4">
      <table class="m-4">
        <thead>
          <tr>
            <th>Podcast</th>
            <th>Role</th>
          </tr>
        </thead>
        <tbody>
          {#for {podcast, engagements} <- Enum.group_by(@engagements, &Map.get(&1, :podcast))}
            <tr>
              <td class="px-2"><PodcastButton for={podcast} /></td>
              <td class="px-2">
                {#for engagement <- engagements}
                  <Pill type="success">{engagement.role}</Pill>
                {/for}
              </td>
            </tr>
          {/for}
        </tbody>
      </table>
    </Panel>

    <Panel :if={@gigs != []}
           heading={"Gigs, #{@persona.name} has been engaged in"}
           purpose="gig"
           class="m-4">
      <table class="m-4">
        <thead>
          <tr>
            <th>Date</th>
            <th>Podcast</th>
            <th>Episode</th>
            <th>Role</th>
          </tr>
        </thead>
        <tbody phx-update="append" id="gigs-table-body">
          {#for episode <- ordered_episodes(@grouped_gigs)}
            <tr id={"episode-#{episode.id}"}>
              <td align="right" class="px-2">{episode.publishing_date |> format_date}</td>
              <td class="px-2"><PodcastButton for={episode.podcast} /></td>
              <td class="px-2"><EpisodeButton for={episode} /></td>
              <td class="px-2">
                {#for gig <- @grouped_gigs[episode]}
                  <Pill id={"gig-#{gig.id}"} type="success">{gig.role}</Pill>
                {/for}
              </td>
            </tr>
          {/for}
        </tbody>
      </table>
      <div id="infinite-scroll" phx-hook="InfiniteScroll" data-gigs-page={@gigs_page}></div>
    </Panel>
    """
  end
end
