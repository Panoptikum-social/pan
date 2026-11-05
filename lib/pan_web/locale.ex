defmodule PanWeb.Locale do
  @moduledoc """
  Chooses the interface language (Project #4, #563).

  As a plug, it picks the locale for a request: the logged-in user's
  setting, then the "locale" cookie, then the browser's Accept-Language
  header, then English. The EN/DE switcher in the sidebar sets the cookie
  and, for logged-in users, the setting (PanWeb.LocaleController). It sets the Gettext locale for the request process, assigns
  `:locale` and stores it in the session, so LiveViews get the same one.

  As an `on_mount` hook, it sets the Gettext locale again in the LiveView
  process, which doesn't inherit it from the plug.

  Admin stays English only: the admin pipeline uses `plug PanWeb.Locale,
  force: "en"` and admin LiveViews `on_mount {PanWeb.Locale, :english}`.
  """
  import Plug.Conn

  @locales ~w(en de)
  @default_locale "en"
  @cookie "locale"

  def locales, do: @locales
  def default_locale, do: @default_locale

  def init(opts), do: opts

  def call(conn, force: locale) do
    Gettext.put_locale(PanWeb.Gettext, locale)
    assign(conn, :locale, locale)
  end

  def call(conn, _opts) do
    conn = fetch_cookies(conn)

    locale =
      user_locale(conn.assigns[:current_user]) ||
        supported(conn.cookies[@cookie]) ||
        from_accept_language(get_req_header(conn, "accept-language")) ||
        @default_locale

    Gettext.put_locale(PanWeb.Gettext, locale)

    conn
    |> put_session("locale", locale)
    |> assign(:locale, locale)
  end

  def cookie, do: @cookie

  def on_mount(:english, _params, _session, socket) do
    Gettext.put_locale(PanWeb.Gettext, @default_locale)
    {:cont, Phoenix.Component.assign(socket, :locale, @default_locale)}
  end

  def on_mount(:default, _params, session, socket) do
    locale = supported(session["locale"]) || @default_locale
    Gettext.put_locale(PanWeb.Gettext, locale)
    {:cont, Phoenix.Component.assign(socket, :locale, locale)}
  end

  defp user_locale(%{locale: locale}), do: supported(locale)
  defp user_locale(_no_user), do: nil

  defp supported(locale) when locale in @locales, do: locale
  defp supported(_locale), do: nil

  # "de-AT,de;q=0.9,en;q=0.8" -> the supported language with the highest q
  # value; region suffixes are ignored, so "de-AT" counts as "de".
  defp from_accept_language([header | _]) do
    header
    |> String.split(",", trim: true)
    |> Enum.map(&language_and_quality/1)
    |> Enum.filter(fn {language, quality} -> language in @locales and quality > 0 end)
    |> Enum.sort_by(fn {_language, quality} -> quality end, :desc)
    |> case do
      [{language, _quality} | _] -> language
      [] -> nil
    end
  end

  defp from_accept_language([]), do: nil

  defp language_and_quality(entry) do
    [tag | params] = entry |> String.trim() |> String.split(";")

    language =
      tag
      |> String.split("-")
      |> hd()
      |> String.downcase()

    quality =
      Enum.find_value(params, 1.0, fn param ->
        param |> String.trim() |> String.split("=") |> quality()
      end)

    {language, quality}
  end

  defp quality(["q", value]) do
    case Float.parse(value) do
      {quality, _rest} -> quality
      :error -> 0.0
    end
  end

  defp quality(_param), do: nil
end
