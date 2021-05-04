defmodule PanWeb.Surface.EpisodeCard do
  use Surface.Component
  alias PanWeb.Surface.{EpisodeButton, Icon, PersonaButton}

  prop(for, :map, required: true)

  def render(assigns) do
    ~H"""
    <p><EpisodeButton for={{ @for }}/></p>

    <p :if={{ @for.author_name }} class="mt-1">
      Author <PersonaButton name={{ @for.author_name }} id={{ @for.author_id }} />
    </p>

    <p class="mt-1">
      <If condition={{ @for.publishing_date }}>
        published <Icon name="calendar-heroicons-outline" />
        {{ @for.publishing_date |> Timex.format!("{ISOdate}") }}
      </If>
      <If condition={{ @for.duration }}>
        Duration &nbsp; <Icon name="stopwatch-lineawesome-solid" /> {{ @for.duration}}
      </If>
    </p>

    <p :if={{ @for.subtitle }} class="mt-1">
      <Icon name="photograph-heroicons-outline" /> {{ @for.subtitle }}
    </p>
    """
  end
end
