defmodule PanWeb.Component.ThemeToggle do
  use PanWeb, :html

  # Latte / Mocha / System switch, handled in assets/js/theme_toggle.js
  def render(assigns) do
    ~H"""
    <div class="flex justify-end px-4 pt-2">
      <div class="join" role="group" aria-label="Color theme">
        <button type="button" class="btn btn-xs join-item" data-theme-choice="latte">Latte</button>
        <button type="button" class="btn btn-xs join-item" data-theme-choice="mocha">Mocha</button>
        <button type="button" class="btn btn-xs join-item" data-theme-choice="system">System</button>
      </div>
    </div>
    """
  end
end
