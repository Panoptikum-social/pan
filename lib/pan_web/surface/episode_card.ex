defmodule PanWeb.Surface.EpisodeCard do
  use Surface.Component
  alias PanWeb.Surface.{EpisodeButton, Icon, PersonaButton}
  alias PanWeb.Episode

  prop for, :map, required: true
  data author, :map

  def render(assigns) do
    author = Episode.author(assigns.for)
    ~H"""
    <div aria-label="episode-card">
      <p><EpisodeButton for={{ @for }}/></p>

      <p :if={{ author.name }} class="mt-4">
        <PersonaButton name={{ author.name }} id={{ author.id }} />
      </p>

      <p class="mt-4">
        <If condition={{ @for.publishing_date }}>
          <Icon name="calendar" />
          {{ @for.publishing_date |> Timex.format!("{ISOdate}") }}
        </If>
        <If condition={{ @for.duration }}>
          &npsb; <Icon name="stopwatch-solid" /> {{ @for.duration}}
        </If>
      </p>

      <p :if={{ @for.subtitle }} class="mt-4">
        <Icon name="image" /> {{ @for.subtitle }}
      </p>
    </div>
    """
  end
end
