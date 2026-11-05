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
        {dgettext("frontend", "at")} <Icon.render name="calendar" />
        {Calendar.strftime(@for.inserted_at, "%x")}
      </span>
      <UserButton.render for={@for.user} /> {dgettext("frontend", "recommended")}
    </p>

    <p :if={@for.podcast} class="mt-2">
      {dgettext("frontend", "the podcast")} <PodcastButton.render for={@for.podcast} />
    </p>

    <%= if @for.episode do %>
      <p class="mt-2">
        {dgettext("frontend", "the episode")} <EpisodeButton.render for={@for.episode} />
      </p>
      <p>
        {dgettext("frontend", "from podcast")} <PodcastButton.render for={@for.episode.podcast} />
      </p>
    <% end %>

    <%= if @for.chapter do %>
      <p class="mt-2">
        {dgettext("frontend", "the chapter")}
        <Icon.render name="indent-increase" /> {@for.chapter.title}
      </p>
      <p class="mt-2">
        {dgettext("frontend", "from episode")} <EpisodeButton.render for={@for.chapter.episode} />
      </p>
      <p class="mt-2">
        {dgettext("frontend", "from podcast")}
        <PodcastButton.render for={@for.chapter.episode.podcast} />
      </p>
    <% end %>

    <p class="mt-2">
      {dgettext("frontend", "with")} <Icon.render name="thumb-up" /> <i>„{@for.comment}"</i>
    </p>
    """
  end
end
