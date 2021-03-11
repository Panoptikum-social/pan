defmodule PanWeb.Surface.RecommendationCard do
  use Surface.Component
  alias PanWeb.Surface.{EpisodeButton, PodcastButton, Icon, UserButton}

  prop for, :any, required: true

  def render(assigns) do
    ~H"""
    <p :if={{ @for.podcast }}>
      <PodcastButton for={{ @for.podcast }} />
    </p>

    <If condition={{ @for.episode }} >
      <p><PodcastButton for={{ @for.episode.podcast }} /></p>
      <p class="mt-2">
        <EpisodeButton for={{ @for.episode }} />
      </p>
    </If>

    <If condition={{ @for.chapter }} >
      <p><PodcastButton for={{ @for.chapter.episode.podcast }} /></p>
      <p class="mt-2">
        <EpisodeButton for={{ @for.chapter.episode }} />
      </p>
      <p class="mt-2">
        <Icon name="indent-solid" /> {{ @for.chapter.title }}
      </p>
    </If>

    <p class="mt-2">
      <span :if={{ @for.inserted_at }} class="float-right">
        <Icon name="calendar" />
        {{ @for.inserted_at |> Timex.format!("{ISOdate}") }}
      </span>
      <UserButton for={{ @for.user}} />
    </p>
    <p class="mt-2">
      <Icon name="thumbs-up" /> <i>„{{ @for.comment }}“</i>
    </p>
    """
  end
end
