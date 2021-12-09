defmodule PanWeb.Live.Podcast.FollowOrUnfollowButton do
  use Surface.LiveComponent
  alias PanWeb.{Follow, Podcast}
  alias PanWeb.Surface.Icon

  prop(current_user_id, :integer, required: true)
  prop(podcast, :map, required: true)
  data(following, :boolean, default: false)

  def following(user_id, podcast_id) do
    Follow.find_podcast_follow(user_id, podcast_id) |> is_nil |> Kernel.not
  end

  def handle_event("follow", _params, %{assigns: assigns} = socket) do
    Podcast.follow(assigns.podcast.id, assigns.current_user_id)
    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
      <button :on-click={"follow"}
              class={"text-white",
                     "bg-success": following(@current_user_id, @podcast.id),
                     "bg-danger": !following(@current_user_id, @podcast.id)}>
        {@podcast.followers_count} <Icon name="user-heroicons-outline"/>
      </button>
    """
  end
end
