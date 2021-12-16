defmodule PanWeb.Live.Persona.Show do
  use Surface.LiveView
  import PanWeb.Router.Helpers
  on_mount PanWeb.Live.AssignUserAndAdmin
  alias PanWeb.{Endpoint, Persona, Delegation, Gig, Image, Engagement, Message, User}
  alias PanWeb.Surface.{PodcastButton, EpisodeButton, Pill, Icon}
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
          messages_per_page: 20,
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
    {:noreply, assign(socket, page: assigns.page + 1) |> fetch_gigs()}
  end

  def handle_event("load-more-messages", _, %{assigns: assigns} = socket) do
    {:noreply, assign(socket, page: assigns.page + 1) |> fetch_messages()}
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
    <script>
      $(function() {
        $('[data-toggle="popover"]').popover()
      })
    </script>

    <div class="row">
      <div class="col-md-8" >
        <div class="panel panel-info">
          <div class="panel-heading">
            <h3 class="panel-title">
              {@persona.name}
            </h3>
          </div>
          <div class="panel-body ">
            <div class="row">
              <div class="col-md-8">
                <dl class="dl-horizontal">
                  <dt>Panoptikum-ID</dt>
                  <dd>{@persona.pid}</dd>

                  <dt>Permalink (URI)</dt>
                  <dd>{Endpoint.url}/{@persona.pid}</dd>

                  <dt>Name</dt>
                  <dd>{@persona.name}</dd>

                  {#if @persona.uri}
                    <dt>Uri</dt>
                    <dd>{ @persona.uri}</dd>
                  {/if}

                  <dt>Business Cards</dt>
                  <dd>
                    <a href={persona_frontend_url(Endpoint, :business_card, @persona)}>
                      <Icon name="credit-card-heroicons-outline"/> Show
                    </a>
                  </dd>
                </dl>
                <span style="color: #fff;">Id: {@persona.id}</span>
              </div>

              <div class="col-md-4" >
                {#if @persona_thumbnail}
                  <img src={"#{@persona_thumbnail.path}#{@persona_thumbnail.filename}"}
                       width="150"
                       alt={@persona.image_title}
                       class="thumbnail"
                       id="photo" />
                {#else}
                  <img src="/images/missing-persona.png"
                       alt="missing image"
                       width="150"
                       class="thumbnail" />
                {/if}
              </div>
            </div>

            <p :if={@current_user_id}>
              <LikeOrUnlikeButton id="like_or_unlike_button"
                                  persona={@persona}
                                  current_user_id={@current_user_id} />
              <FollowOrUnfollowButton id="follow_or_unfollow_button"
                                      persona={@persona}
                                      current_user_id={@current_user_id} />
            </p>
          </div>
        </div>
      </div>
      <div class="col-md-4" >
        {#if !@current_user}
          <div class="alert alert-warning">
            <h4>Claiming not available</h4>
            <p>You can only claim personas, if you are logged in.</p>
          </div>

        {#elseif !@current_user.podcaster}
          <div class="alert alert-warning">
            <h4>Claiming not available</h4>
            <p>You didn't say you are a podcaster in
              <a href={user_frontend_path(Endpoint, :my_profile)}
                 class="btn btn-sm btn-default">My Profile</a> yet.</p>
          </div>

        {#elseif !@current_user.email_confirmed}
          <div class="alert alert-warning">
            <h4>Claiming not available</h4>
            <p>You didn't confirm your email address by clicking on the
              confirmation link in the email sent to you after login.</p>
          </div>

        {#elseif !@persona.email}
          <h4>Claiming</h4>

          <p>Please take the time to read the text on the following screen carefully.</p>

          <p><a href={persona_frontend_path(Endpoint, :warning, @persona)}
                class: "btn btn-normal">Start claiming process</a></p>

        {#else}
          <h4>Claiming</h4>

          {#if Pan.Repo.get_by(PanWeb.Manifestation, persona_id: @persona.id,
                                                     user_id: @current_user.id)}
            <p>You have claimed this persona already.</p>
          {#else}
            <p>You can send an email to the owner of this persona and ask her for permission
              to add you as a manifestation of this persona.<br/>
              Your name, username and email address will be sent alongside in the email
              to give the owner a chance to get in contact with you.</p>

            <p>
              <a href={persona_frontend_path(Endpoint, :claim, @persona)}
                 class="btn btn-normal",
                 method="post"
                 data={[confirm: "Are you sure?"]} >Claim</a>
            </p>
          {/if}
        {/if}
      </div>
    </div>

    <div :if={@persona.description || @persona.long_description}
          class="panel panel-success">
      <div class="panel-heading">
        <h3 class="panel-title">{@persona.description}</h3>
      </div>
      <div class="panel-body">
        {@persona.long_description |> markdown}
      </div>
    </div>

    <div :if={@engagements != []}
          class="panel panel-primary">
      <div class="panel-heading">
        <h3 class="panel-title">Engagements, {@persona.name} has entered</h3>
      </div>
      <div class="table-responsive">
        <table class="table table-striped table-condensed">
          <thead>
            <tr>
              <th>Podcast</th>
              <th>Role</th>
            </tr>
          </thead>
          <tbody>
            {#for {podcast, engagements} <- Enum.group_by(@engagements, &Map.get(&1, :podcast))}
              <tr>
                <td><PodcastButton for={podcast} /></td>
                <td>
                  {#for engagement <- engagements}
                    <Pill type="success">{engagement.role}</Pill> &nbsp;
                  {/for}
                </td>
              </tr>
            {/for}
          </tbody>
        </table>
      </div>
    </div>

    {#if @gigs != []}
      <div class="panel panel-primary" id="gigs">
        <div class="panel-heading">
          <h3 class="panel-title">Gigs, {@persona.name} has been engaged in</h3>
        </div>
      </div>

      <table class="table table-striped table-condensed">
        <thead>
          <tr>
            <th>Date</th>
            <th>Podcast</th>
            <th>Episode</th>
            <th>Role</th>
          </tr>
        </thead>
        <tbody>
          {#for episode <- ordered_episodes(@grouped_gigs)}
            <tr>
              <td align="right">{episode.publishing_date |> format_date}</td>
              <td><PodcastButton for={episode.podcast} /></td>
              <td><EpisodeButton for={episode} /></td>
              <td>
                {#for gig <- @grouped_gigs[episode]}
                  <Pill type="success">{gig.role}</Pill>
                {/for}
              </td>
            </tr>
          {/for}
        </tbody>
      </table>
    {/if}

    <div if={@messages != []}
          class="panel panel-primary">
      <div class="panel-heading">
        <h3 class="panel-title">Messages created by {@persona.name}</h3>
      </div>
      <div class="panel-body">
        <ul class="list-group">
          {#for message <- @messages}
            <li class={"list-group-item message-#{message.type}"}>
              <i>
                {message.creator && message.creator.name || message.persona.name}:
              </i>
              {raw message.content}
              <span class="pull-right">{message.inserted_at |> format_datetime}</span>
            </li>
          {/for}
        </ul>
      </div>
    </div>
    """
  end
end
