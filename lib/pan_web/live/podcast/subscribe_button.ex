defmodule PanWeb.Live.Podcast.SubscribeButton do
  use PanWeb, :live_component
  alias PanWeb.{Subscription, Podcast}
  alias PanWeb.Component.Icon

  def mount(socket) do
    {:ok, assign(socket, subscribed: false)}
  end

  def update(assigns, socket) do
    subscribed =
      Subscription.find_podcast_subscription(assigns.current_user_id, assigns.podcast.id)
      |> is_nil
      |> Kernel.not()

    socket =
      assign(socket, assigns)
      |> assign(subscribed: subscribed)

    {:ok, socket}
  end

  def handle_event("toggle-subscribe", _params, %{assigns: assigns} = socket) do
    Podcast.subscribe(assigns.podcast.id, assigns.current_user_id)

    socket =
      assign(socket,
        subscribed: !assigns.subscribed,
        podcast: Podcast.get_by_id(assigns.podcast.id)
      )

    {:noreply, socket}
  end

  attr :current_user_id, :integer, required: true
  attr :podcast, :map, required: true

  def render(assigns) do
    ~H"""
    <span>
      <button :if={@subscribed}
              phx-click="toggle-subscribe"
              class="btn btn-success btn-sm my-2">
        {@podcast.subscriptions_count} <Icon.render name="user-heroicons-solid"/> Unsubscribe
      </button>
      <button :if={!@subscribed}
              phx-click="toggle-subscribe"
              class="btn btn-error btn-sm my-2">
        {@podcast.subscriptions_count} <Icon.render name="user-heroicons-outline"/> Subscribe
      </button>
    </span>
    """
  end
end
