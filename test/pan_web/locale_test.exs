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
end
