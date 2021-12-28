defmodule PanWeb.Live.User.Show do
  use Surface.LiveView
  on_mount PanWeb.Live.AssignUserAndAdmin
  alias PanWeb.{User, Like, Message}
  alias PanWeb.Surface.{Panel, PodcastButton, CategoryButton, UserButton, EpisodeButton, Icon}
  alias PanWeb.Live.User.{LikeButton, FollowButton}

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

  defp format_datetime(date_time) do
    Timex.to_date(date_time)
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

      <Panel :if={@latest_messages != []}
             purpose="message"
             heading={"Messages created by #{@user.name}"}
             class="my-4">
        <ul class="leading-10"
            phx-update="append"
            id="message-list">
          {#for message <- @latest_messages}
            <li id={"message-#{message.id}"}
                class="flex justify-between border-t border-gray-light">
              <div class="mx-4">
                <i class={"p-1 bg-success-light bg-#{message.type}-light"}>{#if message.creator} {message.creator.name} {#else} {message.persona.name} {/if}:</i>
                {raw message.content}
              </div>
              <div class="mx-4">
                {message.inserted_at |> format_datetime}
              </div>
            </li>
          {/for}
        </ul>
      </Panel>
    </div>
    <div id="infinite-scroll" phx-hook="InfiniteScroll" data-page={@page}></div>
    """
  end
end
