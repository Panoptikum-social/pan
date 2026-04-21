defmodule PanWeb.Live.Podcast.Show do
  use PanWeb, :live_view
  on_mount PanWeb.Live.AssignUserAndAdmin

  alias PanWeb.{Recommendation, Podcast, Episode, Image}
  alias PanWeb.Live.Podcast.{Header, RecommendationList, EpisodeList}

  def mount(%{"id" => id}, _session, socket) do
    podcast = Podcast.get_by_id_for_show(id)

    socket =
      assign(socket,
        podcast: podcast,
        page: 1,
        per_page: 10,
        changeset: %Recommendation{} |> Recommendation.changeset(),
        podcast_thumbnail: Image.get_by_podcast_id(id) || %{},
        page_title: podcast.title <> " (Podcast)"
      )
      |> fetch

    Phoenix.PubSub.subscribe(:pan_pubsub, "podcasts:#{id}")

    {:ok, socket, temporary_assigns: [episodes: []]}
  end

  defp fetch(%{assigns: %{podcast: podcast, page: page, per_page: per_page}} = socket) do
    assign(socket,
      episodes: Episode.get_by_podcast_id(podcast.id, page, per_page),
      episodes_count: Episode.count_by_podcast_id(podcast.id)
    )
  end

  def handle_info(%{reload: :now}, %{assigns: %{podcast: podcast}} = socket) do
    {:noreply, assign(socket, podcast: Podcast.get_by_id_for_show(podcast.id)) |> fetch()}
  end

  def handle_info(payload, socket) do
    {:noreply, push_event(socket, "notification", payload)}
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, assign(socket, page: assigns.page + 1) |> fetch()}
  end

  def render(assigns) do
    ~H"""
    <div class="m-4"
         phx-hook="Notification"
         id="notification-hook-target">
      <span :if={@podcast && @podcast.blocked == true}>
        This podcast may not be published here, sorry.
      </span>
      <div :if={!(@podcast && @podcast.blocked == true)}>
        <Header.render current_user_id={@current_user_id}
                admin={@admin}
                podcast={@podcast}
                podcast_thumbnail={@podcast_thumbnail}
                episodes_count={@episodes_count}/>
        <.live_component module={RecommendationList}
                            id="recommendations_list"
                            current_user_id={@current_user_id}
                            podcast={@podcast}
                            changeset={@changeset} />
        <EpisodeList.render episodes={@episodes}
                     page={@page} />
      </div>
    </div>
    """
  end
end
