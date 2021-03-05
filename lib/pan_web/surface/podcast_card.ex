defmodule PanWeb.Surface.PodcastCard do
  use Surface.Component
  alias PanWeb.Surface.{PodcastButton, Icon, PersonaButton}
  import PanWeb.ViewHelpers

  prop for, :map, required: true

  def render(assigns) do
    ~H"""
    <p><PodcastButton for={{ @for }}/></p>

    <p :if={{ @for.inserted_at }} class="mt-2">
      <Icon name="calendar" />
      {{ @for.inserted_at |> Timex.format!("{ISOdate}") }}
    </p>

    <p if={{ @for.author_name }} class="mt-2">
      <PersonaButton name={{ @for.author_name }} id={{ @for.author_id }} />
    </p>

    <p :if={{ @for.description }} class="mt-2">
      <Icon name="image" /> {{ truncate_string(@for.description, 500) }}
    </p>
    """
  end
end
