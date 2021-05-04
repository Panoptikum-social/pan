defmodule PanWeb.Surface.PodcastCard do
  use Surface.Component
  alias PanWeb.Surface.{PodcastButton, Icon, PersonaButton}
  import PanWeb.ViewHelpers

  prop(for, :map, required: true)

  def render(assigns) do
    ~H"""
    <PodcastButton for={{ @for }}/>

    <p :if={{ @for.inserted_at }} class="mt-1">
      <Icon name="calendar-heroicons-outline" />
      {{ @for.inserted_at |> Timex.format!("{ISOdate}") }}
    </p>

    <p if={{ @for.author_name }} class="mt-1">
      Author <PersonaButton name={{ @for.author_name }} id={{ @for.author_id }} />
    </p>

    <p :if={{ @for.description }} class="mt-1">
      <Icon name="photograph-heroicons-outline" /> {{ truncate_string(@for.description, 500) }}
    </p>
    """
  end
end
