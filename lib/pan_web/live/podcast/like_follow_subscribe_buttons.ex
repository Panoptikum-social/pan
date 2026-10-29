defmodule PanWeb.Live.Podcast.ListFollowSubscribeButtons do
  use PanWeb, :live_component
  alias PanWeb.Live.Podcast.SubscribeButton
  alias PanWeb.{Endpoint, Podcast}
  import PanWeb.Router.Helpers
  import Pan.Parser.MyDateTime, only: [now: 0, time_shift: 2, time_diff: 3, in_the_past?: 1]
  alias PanWeb.Component.FollowButton
  alias PanWeb.Component.LikeButton
  alias PanWeb.Component.Icon

  def handle_event("trigger-update", _, %{assigns: %{podcast: podcast}} = socket) do
    Task.start(fn ->
      Pan.Parser.Podcast.update_from_feed(podcast)
      Phoenix.PubSub.broadcast(:pan_pubsub, "podcasts:#{podcast.id}", %{reload: :now})
    end)

    {:noreply, socket}
  end

  attr :id, :string, required: true
  attr :current_user_id, :integer, default: nil
  attr :podcast, :map, required: true

  def render(assigns) do
    ~H"""
    <div>
      <%= if @current_user_id do %>
        <p class="whitespace-nowrap">
          <.live_component
            module={LikeButton}
            id="like_button"
            current_user_id={@current_user_id}
            model={Podcast}
            instance={@podcast}
          />
          <.live_component
            module={FollowButton}
            id="follow_button"
            current_user_id={@current_user_id}
            model={Podcast}
            instance={@podcast}
          />
          <.live_component
            module={SubscribeButton}
            id="subscribe_button"
            current_user_id={@current_user_id}
            podcast={@podcast}
          />
        </p>

        <%= if !@podcast.manually_updated_at or
              time_shift(@podcast.manually_updated_at, minutes: 5) |> in_the_past? do %>
          <div class="mt-4">
            <button
              phx-click="trigger-update"
              phx-target={@myself}
              class="btn btn-outline btn-warning btn-sm"
            >
              <Icon.render name="settings" /> Metadata Update
            </button>
            <span
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
                class="absolute left-0 mx-auto items-center bg-base-200 border border-base-300 p-4 w-96"
              >
                <h1 class="text-3xl">Info</h1>
                <p class="mt-4">
                  You can manually trigger a metadata update for this podcast every 5 minutes,
                  if you are impatient. This still will take some time, so keep track of
                  the status updates. And refresh the page with [F5] when told so..
                </p>
                <button
                  @click="metadataOpen = false"
                  class="btn btn-outline btn-info btn-sm mt-4"
                  x-ref="metadataCloseButton"
                >
                  Close
                </button>
              </div>
            </span>
          </div>
        <% else %>
          <small>
            A manual update will be available in {time_diff(
              time_shift(@podcast.manually_updated_at, minutes: 5),
              now(),
              :seconds
            )} seconds.
          </small>
        <% end %>
        <div :if={is_nil(@podcast.user_id)} class="mt-4">
          <.link
            href={podcast_frontend_path(Endpoint, :claim, @podcast)}
            method="post"
            data-confirm="We will send a confirmation link to the owner address listed in the podcast's feed. Continue?"
            class="btn btn-outline btn-primary btn-sm"
          >
            Claim this podcast
          </.link>
        </div>
        <div :if={Podcast.manageable_by?(@podcast, @current_user_id)} class="mt-4">
          <.link
            navigate={podcast_frontend_path(Endpoint, :check_feed, @podcast)}
            class="btn btn-outline btn-info btn-sm"
          >
            Check feed
          </.link>
        </div>
      <% else %>
        {@podcast.likes_count} <Icon.render name="heart" />
        Likes &nbsp; &nbsp; {@podcast.followers_count}
        <Icon.render name="message" /> Followers &nbsp; &nbsp; {@podcast.subscriptions_count}
        <Icon.render name="user" /> Subscribers
        <p class="mt-4">
          <i>
            <a
              href={user_frontend_path(Endpoint, :new)}
              class="underline hover:text-primary"
            >Sign up</a>
            /
            <a
              href={session_path(Endpoint, :new)}
              class="underline hover:text-primary"
            >Log in</a>
            to like, follow, recommend and subscribe!
          </i>
        </p>
      <% end %>
    </div>
    """
  end
end
