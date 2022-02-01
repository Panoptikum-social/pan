defmodule PanWeb.Live.User.Show do
  use Surface.LiveView
  on_mount PanWeb.Live.AssignUserAndAdmin
  alias PanWeb.{User, Like}

  alias PanWeb.Surface.{
    Panel,
    PodcastButton,
    CategoryButton,
    UserButton,
    EpisodeButton,
    Icon,
    LikeButton,
    FollowButton
  }

  def mount(%{"id" => id}, _session, socket) do
    user = User.get_for_show(id)

    {:ok,
     assign(socket,
       user: user,
       podcast_related_likes: Like.get_podcast_related(id),
       page_title: user.name <> " (User)"
     )}
  end

  def render(assigns) do
    ~F"""
    <div class="m-4">
      <h1 class="text-3xl">{@user.name}</h1>

      <p :if={@current_user_id}>
        <LikeButton id="like_button"
                    current_user_id={@current_user_id}
                    model={User}
                    instance={@user} />
        <FollowButton id="follow_button"
                      current_user_id={@current_user_id}
                      model={User}
                      instance={@user} />
      </p>

      <Panel :if={@user.share_subscriptions}
             purpose="podcast"
             heading={"Podcasts, #{@user.name} has subscribed to"}
             class="my-4">
        <p class="flex flex-wrap my-4">
          {#for podcast <- @user.podcasts_i_subscribed}
            <PodcastButton for={podcast}
                           truncate={true}
                           class="mx-2 my-1" />
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
                {Calendar.strftime(like.inserted_at, "%x")}: &nbsp;
                <PodcastButton for={like.chapter.episode.podcast} class="truncate max-w-full" /> /
                <EpisodeButton for={like.chapter.episode} /> /
                <Icon name="indent-lineawesome-solid" /> {like.chapter.title} />
              {#elseif like.episode_id != nil}
                {Calendar.strftime(like.inserted_at, "%x")}: &nbsp;
                <PodcastButton for={like.episode.podcast} class="truncate max-w-full" /> /
                <EpisodeButton for={like.episode} />
              {#elseif like.podcast_id != nil}
                {Calendar.strftime(like.inserted_at, "%x")}: &nbsp;
                <PodcastButton for={like.podcast} class="truncate max-w-full" />
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
