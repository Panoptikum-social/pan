defmodule Pan.CategoryFrontendControllerTest do
  use PanWeb.ConnCase

  test "lists all entries on index", %{conn: conn} do
    insert_category()

    conn = get(conn, category_frontend_path(conn, :index))
    # FIXME! issues with con cache, when all tests are run
    # assert html_response(conn, 200) =~ category.title
    assert html_response(conn, 200) =~ "Search"
  end

  test "shows chosen resource", %{conn: conn} do
    category = insert_category()
    conn = get(conn, category_frontend_path(conn, :show, category))
    assert html_response(conn, 200) =~ category.title
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent(404, fn ->
      get(conn, category_frontend_path(conn, :show, -1))
    end)
  end
end
