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
end
