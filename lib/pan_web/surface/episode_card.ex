defmodule PanWeb.Surface.EpisodeCard do
  use Surface.Component
  alias PanWeb.Surface.{EpisodeButton, Icon, PersonaButton}

  prop(for, :map, required: true)

  def render(assigns) do
    ~F"""
    <p><EpisodeButton for={@for}/></p>

    <p :if={@for.author_name} class="mt-1">
      <PersonaButton name={@for.author_name} id={@for.author_id} />
    </p>

    <p class="mt-1">
      {#if @for.publishing_date}
        <Icon name="calendar-heroicons-outline" />&nbsp;{Calendar.strftime(@for.publishing_date, "%x")}
      {/if}
      {#if @for.duration}
        - <Icon name="stopwatch-lineawesome-solid" />{@for.duration}
      {/if}
    </p>

    <p :if={@for.subtitle} class="mt-1">
      <Icon name="photograph-heroicons-outline" />&nbsp;{@for.subtitle}
    </p>
    """
  end
end
