defmodule PanWeb.Surface.EpisodeCard do
  use Surface.Component
  alias PanWeb.Surface.{EpisodeButton, Icon, PersonaButton}

  prop for, :map, required: true

  def render(assigns) do
    ~H"""
    <p><EpisodeButton for={{ @for }}/></p>

    <p :if={{ @for.author_name }} class="mt-2">
      <PersonaButton name={{ @for.author_name }} id={{ @for.author_id }} />
    </p>

    <p class="mt-2">
      <If condition={{ @for.publishing_date }}>
        <Icon name="calendar" />
        {{ @for.publishing_date |> Timex.format!("{ISOdate}") }}
      </If>
      <If condition={{ @for.duration }}>
        &nbsp; <Icon name="stopwatch-solid" /> {{ @for.duration}}
      </If>
    </p>

    <p :if={{ @for.subtitle }} class="mt-2">
      <Icon name="image" /> {{ @for.subtitle }}
    </p>
    """
  end
end
