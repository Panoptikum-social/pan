defmodule PanWeb.Component.ThemeToggle do
  use PanWeb, :html

  # Latte / System / Mocha switch in the sidebar, handled in
  # assets/js/theme_toggle.js
  def render(assigns) do
    assigns =
      assign(assigns, :choices, [
        {"latte", "sun", "Latte"},
        {"system", "device-desktop", "System"},
        {"mocha", "moon", "Mocha"}
      ])

    ~H"""
    <div class="mt-4">
      <div class="join" role="group" aria-label="Color theme">
        <button
          :for={{choice, icon, name} <- @choices}
          type="button"
          class="btn btn-xs join-item"
          data-theme-choice={choice}
          title={name}
          aria-label={name}
        >
          <.icon name={icon} class="size-4" />
        </button>
      </div>
    </div>
    """
  end
end
