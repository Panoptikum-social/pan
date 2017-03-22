defmodule Pan.CategoryFrontendControllerTest do
  use Pan.ConnCase

  setup do
    category = insert_category()
    {:ok, conn: build_conn(), category: category}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, category_frontend_path(conn, :index)
    assert html_response(conn, 200) =~ "Category Title"
  end

  test "shows chosen resource", %{conn: conn, category: category} do
    conn = get conn, category_frontend_path(conn, :show, category)
    assert html_response(conn, 200) =~ "Category Title"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, category_frontend_path(conn, :show, -1)
    end
  end
end
