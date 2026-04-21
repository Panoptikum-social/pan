defmodule PanWeb.Live.Episode.Header do
  use PanWeb, :live_component
  alias PanWeb.{User, Episode}
  alias PanWeb.Component.Pill
  alias PanWeb.Component.LikeButton
  alias PanWeb.Component.EpisodeButton
  alias PanWeb.Component.PersonaButton
  alias PanWeb.Component.PodcastButton
  alias PanWeb.Component.Icon
  alias PanWeb.Live.Episode.ClaimButton

  def mount(socket) do
    {:ok, assign(socket, current_user: nil)}
  end

  def update(%{current_user_id: current_user_id} = assigns, socket) do
    socket =
      if current_user_id do
        assign(socket, assigns)
        |> assign(current_user: User.get_by_id_with_personas(current_user_id))
      else
        assign(socket, assigns)
      end

    {:ok, socket}
  end

  def update(assigns, socket), do: {:ok, assign(socket, assigns)}

  def render(assigns) do
    ~H"""
    <div>
      <h1 class="leading-10">
        <PodcastButton.render for={@episode.podcast} large />
        &nbsp; / &nbsp;
        <EpisodeButton.render for={@episode} large class="my-2" />
      </h1>

      <div class="flex flex-col md:flex-row my-4 space-y-4 md:space-y-0 md:space-x-4 md:divide-x md:divide-dotted md:divide-gray">
        <%= if (@episode.description && @episode.description != @episode.shownotes) ||
              (@episode.summary && @episode.summary != @episode.description) do %>
          <div class="flex-1">
            <%= if @episode.description && @episode.description != @episode.shownotes do %>
              <h2 class="text-2xl">Description</h2>
              <p>{@episode.description |> HtmlSanitizeEx.strip_tags}</p>
            <% end %>

            <%= if @episode.summary && @episode.summary != @episode.description do %>
              <h2 class="text-2xl">Summary</h2>
              <p>{raw(@episode.summary)}</p>
            <% end %>
          </div>
        <% end %>

        <dl class="flex-1 grid content-start grid-cols-4 gap-x-4 gap-y-2">
          <dt class="justify-self-end font-medium">Subtitle</dt>
          <dd class="col-span-3">{@episode.subtitle}</dd>
          <%= if @episode.payment_link_url do %>
            <dt class="justify-self-end font-medium">Support</dt>
            <dd class="col-span-3"><a href={@episode.payment_link_url}>{@episode.payment_link_title}</a></dd>
          <% end %>
          <dt class="justify-self-end font-medium">Duration</dt>
          <dd class="col-span-3">{@episode.duration}</dd>
          <%= if @episode.publishing_date do %>
            <dt class="text-right font-medium">Publishing date</dt>
            <dd class="col-span-3">{Calendar.strftime(@episode.publishing_date, "%x %H:%M")}</dd>
          <% end %>
          <%= if @episode.link do %>
            <dt class="justify-self-end font-medium">Link</dt>
            <dd class="col-span-3">
              <a class="text-link hover:text-link-dark" href={@episode.link}>{@episode.link}</a>
            </dd>
          <% end %>
          <%= if @episode.deep_link do %>
            <dt class="justify-self-end font-medium">Deep link</dt>
            <dd class="col-span-3">
              <a href={@episode.deep_link}
                 id="metadata"
                 class="text-link hover:text-link-dark">{@episode.deep_link}</a>
            </dd>
          <% end %>
          <dt class="justify-self-end font-medium">Contributors</dt>
          <%= for {persona, gigs} <- @episode.gigs |> Enum.group_by(&Map.get(&1, :persona)) do %>
            <dd class="col-start-2 col-span-2">
              <PersonaButton.render for={persona}/>
            </dd>
            <dd class="col-start-4">
              <%= for gig <- gigs do %>
                <Pill.render type="success" id={"gig-#{gig.id}"}>{gig.role}</Pill.render>
                <span :if={gig.self_proclaimed}
                      class="relative"
                      x-data="{ metadataOpen: false }">
                  <div class="inline"
                       @click="metadataOpen = !metadataOpen
                               $nextTick(() => $refs.metadataCloseButton.focus())">
                    <Icon.render name="information-circle-heroicons" />
                  </div>
                  <div x-show="metadataOpen"
                       class="absolute right-0 mx-auto items-center bg-gray-lightest border border-gray p-4 w-96 z-10">
                    <h1 class="text-3xl">Info</h1>
                    <p class="mt-4">
                      This contribution is claimed by a user and not source of the podcast feed.
                    </p>
                    <button @click="metadataOpen = false"
                            class="bg-info hover:bg-info-light text-white p-2 rounded mt-4
                                  focus:ring-2 focus:ring-info-light"
                            x-ref="metadataCloseButton">
                      Close
                    </button>
                  </div>
                </span>
                &nbsp;
              <% end %>
            </dd>
          <% end %>

          <dt class="justify-self-end font-medium">Enclosures</dt>
          <%= for enclosure <- @episode.enclosures do %>
            <dd class="col-start-2 col-span-2">
              <a class="text-link hover:text-link-dark wrap-break-word"
                 href={enclosure.url |> String.trim}>{enclosure.url}</a>
              <%= if is_integer(enclosure.length) do %>
                ({Float.round(String.to_integer(enclosure.length) / 1048576, 1)} MB)
              <% end %>
            </dd>
            <dd class="col-start-4"><Pill.render type="info">{enclosure.type}</Pill.render></dd>
          <% end %>
        </dl>
      </div>

      <div :if={@current_user_id} class="my-4">
        <h3 class="text-xl">Claim contribution</h3>
        <p class="mb-4 leading-10">
          <.live_component :for={persona <- @current_user.personas}
                           module={ClaimButton}
                           id={"claim_persona_#{persona.id}_button"}
                           current_user_id={@current_user_id}
                           persona={persona}
                           episode_id={@episode.id}
                           caller={__MODULE__}
                           caller_id={@id} />
        </p>
      </div>

      <p :if={@current_user_id} class="my-4">
        <.live_component module={LikeButton}
                         id="like_episode_button"
                         current_user_id={@current_user_id}
                         model={Episode}
                         instance={@episode} />
      </p>
    </div>
    """
  end
end
