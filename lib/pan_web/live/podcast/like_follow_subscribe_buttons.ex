defmodule PanWeb.Live.Podcast.ListFollowSubscribeButtons do
  use Surface.Component
  alias PanWeb.Endpoint
  alias PanWeb.Live.Podcast.{LikeOrUnlikeButton, FollowOrUnfollowButton, SubscribeOrUnsubscribeButton}
  import PanWeb.Router.Helpers
  alias PanWeb.Surface.{Icon, LinkButton}

  prop(current_user_id, :integer, required: true)
  prop(podcast, :map, required: true)

  def render(assigns) do
    ~F"""
      {#if @current_user_id}
        <p>
          <LikeOrUnlikeButton id="like_or_unlike_button"
                              current_user_id={@current_user_id}
                              podcast={@podcast} />
          <FollowOrUnfollowButton id="follow_or_unfollow_button"
                                  current_user_id={@current_user_id}
                                  podcast={@podcast} />
          <SubscribeOrUnsubscribeButton id="subscribe_or_unsubscribe_button"
                                        current_user_id={@current_user_id}
                                        podcast={@podcast} />
        </p>

        {#if !@podcast.manually_updated_at or
              (Timex.compare(Timex.shift(@podcast.manually_updated_at, hours: 1), Timex.now()) == -1)}
          <p class="mt-8">
            You can manually trigger a metadata update for this podcast once an hour,
                                  if you are impatient. This still will take some time, so keep track of
                                  the status updates. And refresh the page with [F5] when told so.

          </p>
          <p class="mt-4">
            <LinkButton to={podcast_frontend_path(Endpoint, :trigger_update, @podcast)}
                        class="border border-gray-darker rounded text-white bg-danger hover:bg-danger-light"
                        icon="cog-heroicons-outline"
                        title="Metadata Update"/>
          </p>
          {#else}
          <small>
            A manual update will be available in
            {Timex.Comparable.diff(Timex.shift(@podcast.manually_updated_at, hours: 1), Timex.now(), :minutes)}
            minutes.
          </small>
        {/if}
      {#else}
        {@podcast.likes_count} <Icon name="heart-heroicons-outline"/> Likes &nbsp; &nbsp;
        {@podcast.followers_count}  <Icon name="annotation-heroicons-outline"/> Followers &nbsp; &nbsp;
        {@podcast.subscriptions_count} <Icon name="user-heroicons-outline"/> Subscribers

        <p class="mt-4"><i>
          <a href={user_frontend_path(Endpoint, :new)}
             class="text-link hover:text-link-dark">Sign up</a> /
          <a href={session_path(Endpoint, :new)}
             class="text-link hover:text-link-dark">Log in</a> to like, follow, recommend and subscribe!
        </i></p>
      {/if}

      <script>
        $(function() {
          $('[data-toggle="popover"]').popover()
        })
      </script>
    """
    end
  end
