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
      <h1 class="flex flex-wrap items-center gap-x-3 gap-y-1 my-2">
        <PodcastButton.render for={@episode.podcast} large />
        <span class="text-xl">/</span>
        <EpisodeButton.render for={@episode} large />
      </h1>

      <div class="flex flex-col md:flex-row my-4 space-y-4 md:space-y-0 md:space-x-4 md:divide-x md:divide-dotted md:divide-base-300">
        <%= if (@episode.description && @episode.description != @episode.shownotes) ||
              (@episode.summary && @episode.summary != @episode.description) do %>
          <div class="flex-1">
            <%= if @episode.description && @episode.description != @episode.shownotes do %>
              <h2 class="text-2xl">Description</h2>
              <p>{@episode.description |> HtmlSanitizeEx.strip_tags()}</p>
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
            <dd class="col-span-3">
              <a href={@episode.payment_link_url}>{@episode.payment_link_title}</a>
            </dd>
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
              <a class="underline hover:text-primary" href={@episode.link}>{@episode.link}</a>
            </dd>
          <% end %>
          <%= if @episode.deep_link do %>
            <dt class="justify-self-end font-medium">Deep link</dt>
            <dd class="col-span-3">
              <a
                href={@episode.deep_link}
                id="metadata"
                class="underline hover:text-primary"
              >{@episode.deep_link}</a>
            </dd>
          <% end %>
          <dt class="justify-self-end font-medium">Contributors</dt>
          <%= for {persona, gigs} <- @episode.gigs |> Enum.group_by(&Map.get(&1, :persona)) do %>
            <dd class="col-start-2 col-span-2">
              <PersonaButton.render for={persona} />
            </dd>
            <dd class="col-start-4">
              <%= for gig <- gigs do %>
                <Pill.render type="success" id={"gig-#{gig.id}"}>{gig.role}</Pill.render>
                <span
                  :if={gig.self_proclaimed}
                  class="relative"
                  x-data="metadataToggle"
                >
                  <div
                    class="inline"
                    @click="toggleMetadata"
                  >
                    <Icon.render name="info-circle" />
                  </div>
                  <div
                    x-show="metadataOpen"
                    class="absolute right-0 mx-auto items-center bg-base-200 border border-base-300 p-4 w-96 z-10"
                  >
                    <h1 class="text-3xl">Info</h1>
                    <p class="mt-4">
                      This contribution is claimed by a user and not source of the podcast feed.
                    </p>
                    <button
                      @click="metadataOpen = false"
                      class="btn btn-info btn-sm mt-4"
                      x-ref="metadataCloseButton"
                    >
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
              <a
                class="underline hover:text-primary wrap-break-word"
                href={enclosure.url |> String.trim()}
              >{enclosure.url}</a>
              <%= case Integer.parse(enclosure.length || "") do %>
                <% {bytes, ""} when bytes > 0 -> %>
                  ({Float.round(bytes / 1_048_576, 1)} MB)
                <% _ -> %>
              <% end %>
            </dd>
            <dd class="col-start-4">
              <Pill.render type="info">{enclosure.type}</Pill.render>
            </dd>
          <% end %>
        </dl>
      </div>

      <div :if={@current_user_id} class="my-4">
        <h3 class="text-xl">Claim contribution</h3>
        <p class="mb-4 leading-10">
          <.live_component
            :for={persona <- @current_user.personas}
            module={ClaimButton}
            id={"claim_persona_#{persona.id}_button"}
            current_user_id={@current_user_id}
            persona={persona}
            episode_id={@episode.id}
            caller={__MODULE__}
            caller_id={@id}
          />
        </p>
      </div>

      <p :if={@current_user_id} class="my-4">
        <.live_component
          module={LikeButton}
          id="like_episode_button"
          current_user_id={@current_user_id}
          model={Episode}
          instance={@episode}
        />
      </p>
    </div>
    """
  end
end
