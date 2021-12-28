defmodule PanWeb.Live.Podcast.SubscribeButton do
  use Surface.LiveComponent
  alias PanWeb.{Subscription, Podcast}
  alias PanWeb.Surface.Icon

  prop(current_user_id, :integer, required: true)
  prop(podcast, :map, required: true)
  data(subscribed, :boolean, default: false)

  def handle_event("toggle-subscribe", _params, %{assigns: assigns} = socket) do
    Podcast.subscribe(assigns.podcast.id, assigns.current_user_id)

    socket =
      assign(socket,
        subscribed: !assigns.subscribed,
        podcast: Podcast.get_by_id(assigns.podcast.id)
      )

    {:noreply, socket}
  end

  def render(assigns) do
    subscribed =
      Subscription.find_podcast_subscription(assigns.current_user_id, assigns.podcast.id)
      |> is_nil
      |> Kernel.not()

    assigns = assign(assigns, subscribed: subscribed)

    ~F"""
      <span>
        {#if @subscribed}
          <button :on-click="toggle-subscribe"
                  class="text-white rounded py-1 px-2 bg-success border border-gray-darker rounded">
            {@podcast.subscriptions_count} <Icon name="user-heroicons-solid"/> Unsubscribe
          </button>
        {#else}
          <button :on-click="toggle-subscribe"
                  class="text-white rounded py-1 px-2 bg-danger border border-gray-darker rounded">
            {@podcast.subscriptions_count} <Icon name="user-heroicons-outline"/> Subscribe
          </button>
        {/if}
      </span>
    """
  end
end
