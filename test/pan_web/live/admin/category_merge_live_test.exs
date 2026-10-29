defmodule PanWeb.Live.Admin.CategoryMergeLiveTest do
  use PanWeb.ConnCase

  import Phoenix.LiveViewTest
  alias Pan.Repo
  alias PanWeb.{Category, CategoryMapping, User}

  defp as_admin(conn) do
    n = System.unique_integer([:positive])

    admin =
      Repo.insert!(%User{
        name: "Admin",
        username: "cm_#{n}",
        email: "cm_#{n}@example.com",
        admin: true
      })

    init_test_session(conn, %{"user_id" => admin.id, "admin" => true})
  end

  test "the mappings tab lists the mappings, deleting one removes it", %{conn: conn} do
    target = Repo.insert!(%Category{title: "Target #{System.unique_integer([:positive])}"})
    mapping = CategoryMapping.put("Old parent", "Old name", target.id)

    {:ok, view, html} = live(as_admin(conn), "/admin/categories/merge")
    assert html =~ "Merge Categories"
    refute has_element?(view, "#category-mappings")

    view |> element("a[role=tab]", "Mappings") |> render_click()
    assert_patch(view, "/admin/categories/merge?tab=mappings")
    refute has_element?(view, "button", "Merge Categories")
    assert has_element?(view, "#category-mapping-#{mapping.id}", "Old parent › Old name")

    view |> element("#category-mapping-#{mapping.id} button") |> render_click()
    refute has_element?(view, "#category-mapping-#{mapping.id}")
    refute CategoryMapping.target("Old parent", "Old name")
  end

  test "the icons tab sets icon and color, clears the icon again", %{conn: conn} do
    parent = Repo.insert!(%Category{title: "Picker #{System.unique_integer([:positive])}"})
    child = Repo.insert!(%Category{title: "Books", parent_id: parent.id})

    {:ok, view, _html} = live(as_admin(conn), "/admin/categories/merge?tab=icons")
    assert has_element?(view, "#category-icons")
    refute has_element?(view, "#icon-editor")

    view |> element("#category-icon-#{parent.id} button") |> render_click()
    view |> element("#icon-editor button[phx-value-color=peach]") |> render_click()
    assert Repo.get!(Category, parent.id).color == "peach"

    view |> element("#category-icon-#{child.id} button") |> render_click()
    assert has_element?(view, "#icon-editor", "Subcategories use their parent's color")
    refute has_element?(view, "#icon-editor button[phx-value-color]")

    view |> element("#icon-editor form") |> render_change(%{"query" => "book"})
    view |> element("#icon-editor button[phx-value-icon=book]") |> render_click()
    assert Repo.get!(Category, child.id).icon == "book"
    assert has_element?(view, "#category-icon-#{child.id} td", "book")

    view |> element("#icon-editor button[phx-value-icon=\"\"]") |> render_click()
    assert Repo.get!(Category, child.id).icon == nil
  end
end
