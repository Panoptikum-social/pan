defmodule PanWeb.TranslationsTest do
  # not async: the translations cache is global (persistent_term)
  use PanWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Pan.Repo
  alias PanWeb.{Category, Language, Translations, User}

  setup do
    Translations.refresh()
    on_exit(&Translations.refresh/0)

    parent =
      Repo.insert!(%Category{
        title: "Arts #{System.unique_integer()}",
        title_translations: %{"de" => "Kunst"}
      })

    child = Repo.insert!(%Category{title: "Untranslated", parent_id: parent.id})
    %{parent: parent, child: child}
  end

  test "German gets the translation, English and missing ones the title", %{
    parent: parent,
    child: child
  } do
    Gettext.put_locale(PanWeb.Gettext, "de")
    assert Translations.category_title(parent) == "Kunst"
    assert Translations.category_title(to_string(parent.id), parent.title) == "Kunst"
    assert Translations.category_title(child) == "Untranslated"

    Gettext.put_locale(PanWeb.Gettext, "en")
    assert Translations.category_title(parent) == parent.title
  end

  test "language names are shared by all rows of a group" do
    n = System.unique_integer([:positive])
    de = Repo.insert!(%Language{shortcode: "x#{n}", name: "Xish #{n}"})
    de_at = Repo.insert!(%Language{shortcode: "x#{n}-at", name: "Xish #{n}"})

    Language.put_translation([de.id, de_at.id], "de", "Xisch")

    Gettext.put_locale(PanWeb.Gettext, "de")
    assert Translations.language_name(de) == "Xisch"
    assert Translations.language_name(de_at.id, de_at.name) == "Xisch"
  after
    Gettext.put_locale(PanWeb.Gettext, "en")
  end

  test "the category page shows the German title", %{conn: conn, parent: parent} do
    html =
      conn
      |> put_req_cookie("locale", "de")
      |> get("/categories/#{parent.id}")
      |> html_response(200)

    assert html =~ ~r/<\/svg>\s*Kunst\s*</
    refute html =~ parent.title
  end

  test "the admin page saves and removes a German title", %{conn: conn, child: child} do
    n = System.unique_integer([:positive])

    admin =
      Repo.insert!(%User{
        name: "Admin",
        username: "tr_#{n}",
        email: "tr_#{n}@example.com",
        admin: true,
        locale: "de"
      })

    {:ok, view, html} =
      conn
      |> init_test_session(%{"user_id" => admin.id, "admin" => true})
      |> live("/admin/translations")

    # admin stays English, also for a German admin
    assert html =~ "Only rows without German"

    view
    |> form("#category-#{child.id} form", %{"text" => "Unübersetzt"})
    |> render_submit()

    assert Repo.get!(Category, child.id).title_translations == %{"de" => "Unübersetzt"}

    view
    |> form("#category-#{child.id} form", %{"text" => " "})
    |> render_submit()

    assert Repo.get!(Category, child.id).title_translations == %{}
  end

  test "known roles get translated, unknown ones stay as stored (#571)" do
    Gettext.put_locale(PanWeb.Gettext, "de")
    assert Translations.role("guest") == "Gast"
    assert Translations.role("co-host") == "Co-Host"
    assert Translations.role("chief vibes officer") == "chief vibes officer"

    Gettext.put_locale(PanWeb.Gettext, "en")
    assert Translations.role("guest") == "guest"
  end
end
