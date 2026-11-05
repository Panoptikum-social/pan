defmodule PanWeb.Component.LanguageToggle do
  use PanWeb, :html

  # EN / DE switch in the sidebar, next to the theme toggle, handled in
  # assets/js/language_toggle.js. The choice goes into the "locale" cookie,
  # which PanWeb.Locale reads. Language names stay in their own language.
  attr :locale, :string, default: "en"

  def render(assigns) do
    assigns =
      assign(assigns, :choices, [
        {"en", "EN", "English"},
        {"de", "DE", "Deutsch"}
      ])

    ~H"""
    <div class="mt-2">
      <div class="join" role="group" aria-label={gettext("Language")}>
        <button
          :for={{choice, label, name} <- @choices}
          type="button"
          class={["btn btn-xs join-item", choice == @locale && "btn-active"]}
          data-locale-choice={choice}
          title={name}
          lang={choice}
          aria-pressed={to_string(choice == @locale)}
        >
          {label}
        </button>
      </div>
    </div>
    """
  end
end
