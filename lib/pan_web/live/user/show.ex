defmodule PanWeb.Live.User.Show do
  use Surface.LiveView
  on_mount PanWeb.Live.Auth
  alias PanWeb.{User, Like, Message}
  alias PanWeb.Surface.{PodcastButton, CategoryButton, UserButton, EpisodeButton, Icon}
  alias PanWeb.Live.User.{LikeOrUnlikeButton, FollowOrUnfollowButton}

  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     assign(socket,
       user: User.get_for_show(id),
       podcast_related_likes: Like.get_podcast_related(id),
       page: 1,
       per_page: 15
     )
     |> fetch(), temporary_assigns: [latest_messages: []]}
  end

  defp fetch(%{assigns: %{user: user, page: page, per_page: per_page}} = socket) do
    assign(socket, latest_messages: Message.created_by_user(user.id, page, per_page))
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, assign(socket, page: assigns.page + 1) |> fetch()}
  end

  defp format_date(date) do
    Timex.to_date(date)
    |> Timex.format!("%e.%m.%Y", :strftime)
  end

  def render(assigns) do
    ~F"""
    <h1 class="text-3xl">{@user.name}</h1>

    <p :if={@current_user_id}>
      <LikeOrUnlikeButton id="like_or_unlike_button"
                          current_user_id={@current_user_id}
                          user={@user} />
      <FollowOrUnfollowButton id="follow_or_unfollow_button"
                               current_user_id={@current_user_id}
                               user={@user} />
    </p>

    <div class="row">
      {#if @user.share_subscriptions}
        <div class="col-md-6">
          <div class="panel panel-primary">
            <div class="panel-heading">
              <h3 class="panel-title">Podcasts, {@user.name} has subscribed to</h3>
            </div>
            <div class="panel-body">
            <p style="line-height: 200%;">
                {#for podcast <- @user.podcasts_i_subscribed}
                  <PodcastButton for={podcast} /> &nbsp;
                {/for}
              </p>
            </div>
          </div>
        </div>
      {/if}

      {#if @podcast_related_likes != []}
        <div class="col-md-12">
          <div class="panel panel-danger">
            <div class="panel-heading">
              <h3 class="panel-title">Podcast, {@user.name} likes</h3>
            </div>
            <div class="panel-body">
              {#for like <- @podcast_related_likes}
                <p>
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
          </div>
        </div>
      {/if}

      {#if @user.users_i_like != []}
        <div class="col-md-6">
          <div class="panel panel-info">
            <div class="panel-heading">
              <h3 class="panel-title">Persons, {@user.name} likes</h3>
            </div>
            <div class="panel-body">
              <p style="line-height: 200%;">
                {#for user <- @user.users_i_like}
                  <UserButton for={user} /> &nbsp;
                {/for}
              </p>
            </div>
          </div>
        </div>
      {/if}

      {#if @user.categories_i_like != []}
        <div class="col-md-6">
          <div class="panel panel-primary">
            <div class="panel-heading">
              <h3 class="panel-title">Categories, {@user.name} likes</h3>
            </div>
            <div class="panel-body">
              <p style="line-height: 200%;">
                {#for category <- @user.categories_i_like}
                  <CategoryButton for={category} /> &nbsp;
                {/for}
              </p>
            </div>
          </div>
        </div>
      {/if}

      {#if @latest_messages != [] > 0}
        <div class="col-md-12">
          <div class="panel panel-primary">
            <div class="panel-heading">
              <h3 class="panel-title">Messages created by {@user.name}</h3>
            </div>
            <div class="panel-body">
              <ul class="list-group">
                {#for message <- @latest_messages}
                  <li class={"list-group-item message-#{message.type}"}>
                    <i>{#if message.creator} {message.creator.name} {#else} {message.persona.name} {/if}:</i>
                    {raw message.content}
                    <span class="pull-right">{message.inserted_at}</span>
                  </li>
                {/for}
              </ul>
              <div id="infinite-scroll" phx-hook="InfiniteScroll" data-page={@page}></div>
            </div>
          </div>
        </div>
      {/if}
    </div>
    """
  end
end
