defmodule PanWeb.Component.EpisodeCard do
  use PanWeb, :html
  alias PanWeb.Component.EpisodeButton
  alias PanWeb.Component.PersonaButton
  alias PanWeb.Component.Icon

  attr :for, :map, required: true

  def render(assigns) do
    ~H"""
    <p><EpisodeButton.render for={@for} /></p>

    <p :if={@for.author_name} class="mt-1">
      <PersonaButton.render name={@for.author_name} id={@for.author_id} />
    </p>

    <p class="mt-1">
      <%= if @for.publishing_date do %>
        <Icon.render name="calendar" />&nbsp;{Calendar.strftime(
          @for.publishing_date,
          "%x"
        )}
      <% end %>
      <%= if @for.duration do %>
        - <Icon.render name="stopwatch" />{@for.duration}
      <% end %>
    </p>

    <p :if={@for.subtitle} class="mt-1">
      <Icon.render name="photo" />&nbsp;{@for.subtitle}
    </p>
    """
  end
end
