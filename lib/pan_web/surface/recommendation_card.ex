defmodule PanWeb.Surface.RecommendationCard do
  use Surface.Component
  alias PanWeb.Surface.{EpisodeButton, PodcastButton, Icon, UserButton}

  prop(for, :any, required: true)

  def render(assigns) do
    ~F"""
    <p>
      <span :if={@for.inserted_at} class="float-right">
        at <Icon name="calendar-heroicons-outline" />
        {Calendar.strftime(@for.inserted_at, "%x")}
      </span>
      <UserButton for={@for.user} /> recommended
    </p>

    <p :if={@for.podcast}
       class="mt-2">
      the podcast <PodcastButton for={@for.podcast} />
    </p>

    {#if @for.episode}
      <p class="mt-2">
        the episode <EpisodeButton for={@for.episode} />
      </p>
      <p >
        from podcast <PodcastButton for={@for.episode.podcast} />
      </p>
    {/if}

    {#if @for.chapter}
      <p class="mt-2">
        the chapter <Icon name="indent-lineawesome-solid" /> {@for.chapter.title}
      </p>
      <p class="mt-2">
        from episode  <EpisodeButton for={@for.chapter.episode} />
      </p>
      <p class="mt-2">
        from podcast <PodcastButton for={@for.chapter.episode.podcast} />
      </p>
    {/if}

    <p class="mt-2">
      with <Icon name="thumb-up-heroicons-outline" /> <i>„{@for.comment}“</i>
    </p>
    """
  end
end
