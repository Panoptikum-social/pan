defmodule PanWeb.LocaleTest do
  use PanWeb.ConnCase, async: true

  alias Pan.Repo
  alias PanWeb.User

  defp insert_user(locale) do
    unique = System.unique_integer([:positive])

    Repo.insert!(%User{
      name: "Locale",
      username: "locale_#{unique}",
      email: "locale_#{unique}@example.com",
      locale: locale
    })
  end

  defp run_plug(conn, opts \\ []) do
    conn
    |> Plug.Test.init_test_session(%{})
    |> PanWeb.Locale.call(PanWeb.Locale.init(opts))
  end

  test "defaults to English without cookie or Accept-Language", %{conn: conn} do
    conn = run_plug(conn)

    assert conn.assigns.locale == "en"
    assert get_session(conn, "locale") == "en"
    assert Gettext.get_locale(PanWeb.Gettext) == "en"
  end

  test "picks the supported language with the highest quality", %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept-language", "fr-FR,fr;q=0.9,de-AT;q=0.8,en;q=0.5")
      |> run_plug()

    assert conn.assigns.locale == "de"
    assert Gettext.get_locale(PanWeb.Gettext) == "de"
  end

  test "ignores languages with quality 0 and broken quality values", %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept-language", "de;q=0, en;q=nonsense, it")
      |> run_plug()

    assert conn.assigns.locale == "en"
  end

  test "the cookie wins over Accept-Language", %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept-language", "en")
      |> put_req_cookie("locale", "de")
      |> run_plug()

    assert conn.assigns.locale == "de"
  end

  test "an unsupported cookie value is ignored", %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept-language", "de")
      |> put_req_cookie("locale", "xx")
      |> run_plug()

    assert conn.assigns.locale == "de"
  end

  test "force: \"en\" keeps admin English and leaves the session alone", %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept-language", "de")
      |> run_plug()
      |> PanWeb.Locale.call(PanWeb.Locale.init(force: "en"))

    assert conn.assigns.locale == "en"
    assert get_session(conn, "locale") == "de"
    assert Gettext.get_locale(PanWeb.Gettext) == "en"
  end

  test "on_mount sets the locale from the session" do
    socket = %Phoenix.LiveView.Socket{}

    assert {:cont, socket} =
             PanWeb.Locale.on_mount(:default, %{}, %{"locale" => "de"}, socket)

    assert socket.assigns.locale == "de"
    assert Gettext.get_locale(PanWeb.Gettext) == "de"

    assert {:cont, socket} =
             PanWeb.Locale.on_mount(:english, %{}, %{"locale" => "de"}, socket)

    assert socket.assigns.locale == "en"
    assert Gettext.get_locale(PanWeb.Gettext) == "en"
  end

  test "the page renders in the chosen language, with the switcher showing it", %{conn: conn} do
    html =
      conn
      |> put_req_cookie("locale", "de")
      |> get("/")
      |> html_response(200)

    assert html =~ ~s(<html lang="de")
    assert html =~ ~s(aria-label="Sprache")
    assert html =~ ~r/class="btn btn-xs join-item btn-active"\s+data-locale-choice="de"/
  end

  test "a German browser gets German changeset errors" do
    Gettext.put_locale(PanWeb.Gettext, "de")

    assert PanWeb.CoreComponents.translate_error({"can't be blank", []}) ==
             "darf nicht leer sein"

    assert PanWeb.CoreComponents.translate_error(
             {"should be at least %{count} character(s)", [count: 3]}
           ) == "muss mindestens 3 Zeichen lang sein"
  end

  test "the user setting wins over cookie and Accept-Language", %{conn: conn} do
    user = insert_user("de")

    conn =
      conn
      |> put_req_header("accept-language", "en")
      |> put_req_cookie("locale", "en")
      |> Plug.Test.init_test_session(%{})
      |> assign(:current_user, user)
      |> PanWeb.Locale.call([])

    assert conn.assigns.locale == "de"
  end

  test "a user without a setting falls back to the cookie", %{conn: conn} do
    user = insert_user(nil)

    conn =
      conn
      |> put_req_cookie("locale", "de")
      |> Plug.Test.init_test_session(%{})
      |> assign(:current_user, user)
      |> PanWeb.Locale.call([])

    assert conn.assigns.locale == "de"
  end

  describe "POST /locale" do
    test "logged out: sets the cookie only", %{conn: conn} do
      conn = post(conn, "/locale", %{"locale" => "de"})

      assert response(conn, 204)
      assert conn.resp_cookies["locale"].value == "de"
    end

    test "logged in: sets the cookie and the user setting", %{conn: conn} do
      user = insert_user(nil)

      conn =
        conn
        |> init_test_session(%{"user_id" => user.id})
        |> post("/locale", %{"locale" => "de"})

      assert response(conn, 204)
      assert conn.resp_cookies["locale"].value == "de"
      assert Repo.get!(User, user.id).locale == "de"
    end

    test "rejects unsupported locales", %{conn: conn} do
      user = insert_user("en")

      conn =
        conn
        |> init_test_session(%{"user_id" => user.id})
        |> post("/locale", %{"locale" => "xx"})

      assert response(conn, 400)
      refute conn.resp_cookies["locale"]
      assert Repo.get!(User, user.id).locale == "en"
    end

    test "rejects a missing locale", %{conn: conn} do
      assert conn |> post("/locale", %{}) |> response(400)
    end
  end

  describe "account pages (#578)" do
    import Phoenix.LiveViewTest

    test "the login page renders in German", %{conn: conn} do
      {:ok, _view, html} = conn |> put_req_cookie("locale", "de") |> live("/sessions/new")

      assert html =~ "Anmeldung"
      assert html =~ "30 Tage angemeldet bleiben"
    end

    test "signing up saves the page language as the user setting", %{conn: conn} do
      {:ok, view, _html} = conn |> put_req_cookie("locale", "de") |> live("/users/new")
      unique = System.unique_integer([:positive])

      view
      |> form("#sign-up-form",
        user: %{
          name: "Neue Benutzerin",
          username: "neu_#{unique}",
          email: "neu_#{unique}@example.com",
          password: "geheim1234",
          password_confirmation: "geheim1234",
          bot_check: 42
        }
      )
      |> render_submit()

      assert Repo.get_by!(User, username: "neu_#{unique}").locale == "de"
    end
  end

  test "browsing pages render in German (#579)", %{conn: conn} do
    html = conn |> put_req_cookie("locale", "de") |> get("/communities") |> html_response(200)

    assert html =~ "Die Communitys von Panoptikum"
  end

  test "the login link email goes out in the page language (#583)", %{conn: conn} do
    import Swoosh.TestAssertions
    user = insert_user(nil)

    conn
    |> put_req_cookie("locale", "de")
    |> post("/request_login_link", %{"user" => %{"email" => user.email}})

    assert_email_sent(fn email ->
      email.subject == "Panoptikum - Login-Link" and email.html_body =~ "anmelden"
    end)
  end

  describe "claim request mails (#591, #592)" do
    import Swoosh.TestAssertions
    alias PanWeb.{Engagement, Language, Persona, Podcast}

    defp podcast_in(shortcodes) do
      podcast = Repo.insert!(%Podcast{title: "Sprachpodcast", description: "d"})

      for code <- shortcodes do
        language = Repo.insert!(%Language{shortcode: code, name: code})

        Repo.insert_all("languages_podcasts", [
          %{language_id: language.id, podcast_id: podcast.id}
        ])
      end

      podcast
    end

    test "one supported language decides, several or none mean English" do
      assert PanWeb.Locale.from_language_codes(["de-AT"]) == "de"
      assert PanWeb.Locale.from_language_codes(["de", "de-de", "fr"]) == "de"
      assert PanWeb.Locale.from_language_codes(["de", "en-us"]) == "en"
      assert PanWeb.Locale.from_language_codes(["fr"]) == "en"
      assert PanWeb.Locale.from_language_codes([]) == "en"
    end

    test "the podcast claim mail uses the podcast's language" do
      podcast = podcast_in(["de-at"])
      claimant = insert_user(nil)

      "token"
      |> Pan.Email.confirm_podcast_claim_link_html_email(claimant, podcast, "owner@example.com")
      |> Pan.Mailer.deliver()

      assert_email_sent(fn email ->
        email.subject == "Panoptikum - Anfrage zur Verwaltung eines Podcasts" and
          email.html_body =~ "Sprachpodcast"
      end)

      assert Gettext.get_locale(PanWeb.Gettext) == "en"
    end

    test "the persona claim mail uses the persona's podcasts, unless its user has a setting" do
      podcast = podcast_in(["de"])
      claimant = insert_user(nil)
      persona = Repo.insert!(%Persona{pid: "p-#{claimant.id}", name: "P", email: "p@example.com"})
      Repo.insert!(%Engagement{persona_id: persona.id, podcast_id: podcast.id, role: "host"})

      "token"
      |> Pan.Email.confirm_persona_claim_link_html_email(claimant, persona)
      |> Pan.Mailer.deliver()

      assert_email_sent(fn email ->
        email.subject == "Panoptikum - Anfrage zur Übernahme einer Persona"
      end)

      english_user = insert_user("en")
      persona = Repo.update!(Ecto.Changeset.change(persona, user_id: english_user.id))

      "token"
      |> Pan.Email.confirm_persona_claim_link_html_email(claimant, persona)
      |> Pan.Mailer.deliver()

      assert_email_sent(fn email ->
        email.subject == "Panoptikum - Persona manifestation confirmation request"
      end)
    end
  end

  test "links to the qed site lead German users to /de/ where a translation exists (#586)" do
    Gettext.put_locale(PanWeb.Gettext, "de")
    assert PanWeb.Blog.url("/privacy/") == "https://blog.panoptikum.social/de/privacy/"
    assert PanWeb.Blog.url("/") == "https://blog.panoptikum.social/de/"
    assert PanWeb.Blog.url("/blog/") == "https://blog.panoptikum.social/blog/"
    assert PanWeb.Blog.url("/api/") == "https://blog.panoptikum.social/api/"

    Gettext.put_locale(PanWeb.Gettext, "en")
    assert PanWeb.Blog.url("/privacy/") == "https://blog.panoptikum.social/privacy/"
  end

  test "the footer links to the German legal pages", %{conn: conn} do
    html = conn |> put_req_cookie("locale", "de") |> get("/") |> html_response(200)

    assert html =~ ~s(href="https://blog.panoptikum.social/de/imprint/")
    assert html =~ ~s(href="https://blog.panoptikum.social/de/code-of-conduct/")
  end
end
