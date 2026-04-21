defmodule PanWeb.Live.User.Show do
  use PanWeb, :live_view
  on_mount PanWeb.Live.AssignUserAndAdmin
  alias PanWeb.{User, Like}

  alias PanWeb.Component.Panel
  alias PanWeb.Component.FollowButton
  alias PanWeb.Component.LikeButton
  alias PanWeb.Component.EpisodeButton
  alias PanWeb.Component.UserButton
  alias PanWeb.Component.CategoryButton
  alias PanWeb.Component.PodcastButton
  alias PanWeb.Component.Icon

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
    ~H"""
    <div class="m-4">
      <h1 class="text-3xl">{@user.name}</h1>

      <p :if={@current_user_id}>
        <.live_component module={LikeButton}
                    id="like_button"
                    current_user_id={@current_user_id}
                    model={User}
                    instance={@user} />
        <.live_component module={FollowButton}
                      id="follow_button"
                      current_user_id={@current_user_id}
                      model={User}
                      instance={@user} />
      </p>

      <Panel.render :if={@user.share_subscriptions}
             purpose="podcast"
             heading={"Podcasts, #{@user.name} has subscribed to"}
             class="my-4">
        <p class="flex flex-wrap my-4">
          <PodcastButton.render :for={podcast <- @user.podcasts_i_subscribed}
                         for={podcast}
                         truncate={true}
                         class="mx-2 my-1" />
        </p>
      </Panel.render>

      <Panel.render :if={@podcast_related_likes != []}
             purpose="like"
             heading={"Podcast, #{@user.name} likes"}
             class="my-4">
        <div class="m-4">
          <p :for={like <- @podcast_related_likes} class="leading-10">
            <span :if={like.chapter_id != nil}>
              {Calendar.strftime(like.inserted_at, "%x")}: &nbsp;
              <PodcastButton.render for={like.chapter.episode.podcast} class="truncate max-w-full" /> /
              <EpisodeButton.render for={like.chapter.episode} /> /
              <Icon.render name="indent-lineawesome-solid" /> {like.chapter.title} />
            </span>
            <span :if={like.episode_id != nil && is_nil(like.chapter_id)}>
              {Calendar.strftime(like.inserted_at, "%x")}: &nbsp;
              <PodcastButton.render for={like.episode.podcast} class="truncate max-w-full" /> /
              <EpisodeButton.render for={like.episode} />
            </span>
            <span :if={like.podcast_id != nil && is_nil(like.episode_id) && is_nil(like.chapter_id)}>
              {Calendar.strftime(like.inserted_at, "%x")}: &nbsp;
              <PodcastButton.render for={like.podcast} class="truncate max-w-full" />
            </span>
          </p>
        </div>
      </Panel.render>

      <Panel.render :if={@user.users_i_like != []}
             purpose="popular"
             heading={"Persons, #{@user.name} likes"}
             class="my-4">
        <p class="leading-10 m-4">
          <span :for={u <- @user.users_i_like}>
            <UserButton.render for={u} /> &nbsp;
          </span>
        </p>
      </Panel.render>

      <Panel.render :if={@user.categories_i_like != []}
             purpose="category"
             heading={"Categories, #{@user.name} likes"}
             class="my-4">
        <p class="leading-10 m-4">
          <span :for={category <- @user.categories_i_like}>
            <CategoryButton.render for={category} /> &nbsp;
          </span>
        </p>
      </Panel.render>
    </div>
    """
  end
end
