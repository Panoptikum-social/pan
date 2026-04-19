defmodule PanWeb.Surface.EpisodeCard do
  use PanWeb, :html
  alias PanWeb.Surface.{EpisodeButton, Icon, PersonaButton}

  attr :for, :map, required: true

  def render(assigns) do
    ~H"""
    <p><EpisodeButton.render for={@for} /></p>

    <p :if={@for.author_name} class="mt-1">
      <PersonaButton.render name={@for.author_name} id={@for.author_id} />
    </p>

    <p class="mt-1">
      <%= if @for.publishing_date do %>
        <Icon.render name="calendar-heroicons-outline" />&nbsp;{Calendar.strftime(@for.publishing_date, "%x")}
      <% end %>
      <%= if @for.duration do %>
        - <Icon.render name="stopwatch-lineawesome-solid" />{@for.duration}
      <% end %>
    </p>

    <p :if={@for.subtitle} class="mt-1">
      <Icon.render name="photograph-heroicons-outline" />&nbsp;{@for.subtitle}
    </p>
    """
  end
end
