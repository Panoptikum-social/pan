defmodule PanWeb.Live.User.Show do
  use Surface.LiveView
  on_mount PanWeb.Live.AssignUserAndAdmin
  alias PanWeb.{User, Like}
  alias PanWeb.Surface.{Panel, PodcastButton, CategoryButton, UserButton, EpisodeButton, Icon}
  alias PanWeb.Live.User.{LikeButton, FollowButton}

  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     assign(socket,
       user: User.get_for_show(id),
       podcast_related_likes: Like.get_podcast_related(id)
     )}
  end

  defp format_date(date) do
    Timex.to_date(date)
    |> Timex.format!("%e.%m.%Y", :strftime)
  end

  def render(assigns) do
    ~F"""
    <div class="m-4">
      <h1 class="text-3xl">{@user.name}</h1>

      <p :if={@current_user_id}>
        <LikeButton id="like_button"
                    current_user_id={@current_user_id}
                    user={@user} />
        <FollowButton id="follow_button"
                      current_user_id={@current_user_id}
                      user={@user} />
      </p>

      <Panel :if={@user.share_subscriptions}
             purpose="podcast"
             heading={"Podcasts, #{@user.name} has subscribed to"}
             class="my-4">
        <p class="leading-10 m-4">
          {#for podcast <- @user.podcasts_i_subscribed}
            <PodcastButton for={podcast}
                           truncate={true}/> &nbsp;
          {/for}
        </p>
      </Panel>

      <Panel :if={@podcast_related_likes != []}
             purpose="like"
             heading={"Podcast, #{@user.name} likes"}
             class="my-4">
        <div class="m-4">
          {#for like <- @podcast_related_likes}
            <p class="leading-10">
              {#if like.chapter_id != nil}
                {like.inserted_at |> format_date}: &nbsp;
                <PodcastButton for={like.chapter.episode.podcast} /> /
                <EpisodeButton for={like.chapter.episode} /> /
                <Icon name="indent-lineawesome-solid" /> {like.chapter.title} />
              {#elseif like.episode_id != nil}
                {like.inserted_at |> format_date}: &nbsp;
                <PodcastButton for={like.episode.podcast} /> /
                <EpisodeButton for={like.episode} />
              {#elseif like.podcast_id != nil}
                {like.inserted_at |> format_date}: &nbsp;
                <PodcastButton for={like.podcast} />
              {/if}
            </p>
          {/for}
        </div>
      </Panel>

      <Panel :if={@user.users_i_like != []}
             purpose="popular"
             heading={"Persons, #{@user.name} likes"}
             class="my-4">
        <p class="leading-10 m-4">
          {#for user <- @user.users_i_like}
            <UserButton for={user} /> &nbsp;
          {/for}
        </p>
      </Panel>

      <Panel :if={@user.categories_i_like != []}
             purpose="category"
             heading={"Categories, #{@user.name} likes"}
             class="my-4">
        <p class="leading-10 m-4">
          {#for category <- @user.categories_i_like}
            <CategoryButton for={category} /> &nbsp;
          {/for}
        </p>
      </Panel>
    </div>
    """
  end
end
