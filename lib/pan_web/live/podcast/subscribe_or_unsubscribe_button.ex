defmodule PanWeb.Live.Podcast.SubscribeOrUnsubscribeButton do
  use Surface.LiveComponent
  alias PanWeb.{Subscription, Podcast}
  alias PanWeb.Surface.Icon

  prop(current_user_id, :integer, required: true)
  prop(podcast, :map, required: true)
  data(subscribed, :boolean, default: false)

  def subscribed(user_id, podcast_id) do
    Subscription.find_podcast_subscription(user_id, podcast_id) |> is_nil |> Kernel.not
  end

  def handle_event("subscribe", _params, %{assigns: assigns} = socket) do
    Podcast.subscribe(assigns.podcast.id, assigns.current_user_id)
    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
      <button :on-click={"subscribe"}
              class={"text-white",
                     "bg-success": subscribed(@current_user_id, @podcast.id),
                     "bg-danger": !subscribed(@current_user_id, @podcast.id)}>
        {@podcast.subscriptions_count} <Icon name="user-heroicons-outline"/>
      </button>
    """
  end
end
