defmodule PanWeb.LocaleController do
  use PanWeb, :controller
  alias PanWeb.User

  @cookie_max_age 60 * 60 * 24 * 365

  # Called by the EN/DE switcher in the sidebar (assets/js/language_toggle.js),
  # which reloads the page afterwards. Sets the cookie for everybody and the
  # user setting for logged-in users (#563).
  def update(conn, %{"locale" => locale}) when is_binary(locale) do
    if locale in PanWeb.Locale.locales() do
      save_user_locale(conn.assigns.current_user, locale)

      conn
      |> put_resp_cookie(PanWeb.Locale.cookie(), locale,
        max_age: @cookie_max_age,
        same_site: "Lax"
      )
      |> send_resp(:no_content, "")
    else
      send_resp(conn, :bad_request, "")
    end
  end

  def update(conn, _params), do: send_resp(conn, :bad_request, "")

  defp save_user_locale(nil, _locale), do: :ok

  defp save_user_locale(user, locale) do
    user
    |> User.locale_changeset(%{locale: locale})
    |> Repo.update!()
  end
end
