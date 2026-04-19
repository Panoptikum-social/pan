defmodule PanWeb.Surface.PodcastCard do
  use PanWeb, :html
  alias PanWeb.Surface.{PodcastButton, Icon, PersonaButton}
  import PanWeb.ViewHelpers

  attr :for, :map, required: true

  def render(assigns) do
    ~H"""
    <PodcastButton.render for={@for} />

    <p :if={@for.inserted_at} class="mt-1">
      <Icon.render name="calendar-heroicons-outline" />
      {Calendar.strftime(@for.inserted_at, "%x")}
    </p>

    <p :if={@for.author_name} class="mt-1">
      Author <PersonaButton.render name={@for.author_name} id={@for.author_id} />
    </p>

    <p :if={@for.description} class="mt-1">
      <Icon.render name="photograph-heroicons-outline" /> {truncate_string(@for.description, 500)}
    </p>
    """
  end
end
