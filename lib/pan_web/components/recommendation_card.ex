defmodule PanWeb.Component.RecommendationCard do
  use PanWeb, :html
  alias PanWeb.Component.EpisodeButton
  alias PanWeb.Component.PodcastButton
  alias PanWeb.Component.UserButton
  alias PanWeb.Component.Icon

  attr :for, :any, required: true

  def render(assigns) do
    ~H"""
    <p>
      <span :if={@for.inserted_at} class="float-right">
        at <Icon.render name="calendar-heroicons-outline" />
        {Calendar.strftime(@for.inserted_at, "%x")}
      </span>
      <UserButton.render for={@for.user} /> recommended
    </p>

    <p :if={@for.podcast} class="mt-2">
      the podcast <PodcastButton.render for={@for.podcast} />
    </p>

    <%= if @for.episode do %>
      <p class="mt-2">
        the episode <EpisodeButton.render for={@for.episode} />
      </p>
      <p>
        from podcast <PodcastButton.render for={@for.episode.podcast} />
      </p>
    <% end %>

    <%= if @for.chapter do %>
      <p class="mt-2">
        the chapter <Icon.render name="indent-lineawesome-solid" /> {@for.chapter.title}
      </p>
      <p class="mt-2">
        from episode <EpisodeButton.render for={@for.chapter.episode} />
      </p>
      <p class="mt-2">
        from podcast <PodcastButton.render for={@for.chapter.episode.podcast} />
      </p>
    <% end %>

    <p class="mt-2">
      with <Icon.render name="thumb-up-heroicons-outline" /> <i>„{@for.comment}"</i>
    </p>
    """
  end
end
