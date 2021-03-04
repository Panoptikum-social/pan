defmodule PanWeb.Surface.RecommendationCard do
  use Surface.Component
  alias PanWeb.Surface.{EpisodeButton, PodcastButton, Icon, UserButton}

  prop for, :map, required: true

  def render(assigns) do
    ~H"""
    <p :if={{ @for.podcast }} class="mt-4">
      <PodcastButton for={{ @for.podcast }} />
    </p>

    <If condition={{ @for.episode }} >
      <p class="mt-4">
        <PodcastButton for={{ @for.episode.podcast }} />
      </p>
      <p class="mt-4">
        <EpisodeButton for={{ @for.episode }} />
      </p>
    </If>

    <If condition={{ @for.chapter_id }} >
      <p class="mt-4">
        <PodcastButton for={{ @for.chapter.episode.podcast }} />
      </p>
      <p class="mt-4">
        <EpisodeButton for={{ @for.chapter.episode }} />
      </p>
      <p class="mt-4">
        <Icon name="indent-solid" /> {{ @for.chapter.title }}
      </p>
    </If>

    <p class="mt-4">
      <span :if={{ @for.inserted_at }} class="float-right">
        <Icon name="calendar" />
        {{ @for.inserted_at |> Timex.format!("{ISOdate}") }}
      </span>
      <UserButton for={{ @for.user}} />
    </p>
    <p class="mt-4">
      <Icon name="thumbs-up" /> <i>„{{ @for.comment }}“</i>
    </p>
    """
  end
end
