defmodule Pan.CategoryControllerTest do
  use PanWeb.ConnCase

  describe "when user is logged in and is an admin" do
    setup do
      admin = insert_admin_user()
      conn = assign(build_conn(), :current_user, admin)
      {:ok, conn: conn}
    end

    alias PanWeb.Category
    @valid_attrs %{title: "some content"}
    @invalid_attrs %{}

    test "lists all entries on index", %{conn: conn} do
      conn = get conn, category_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing categories"
    end

    test "renders form for new resources", %{conn: conn} do
      conn = get conn, category_path(conn, :new)
      assert html_response(conn, 200) =~ "New category"
    end

    test "creates resource and redirects when data is valid", %{conn: conn} do
      conn = post conn, category_path(conn, :create), category: @valid_attrs
      assert redirected_to(conn) == category_path(conn, :index)
      assert Repo.get_by(Category, @valid_attrs)
    end

    test "does not create resource and renders errors when data is invalid", %{conn: conn} do
      conn = post conn, category_path(conn, :create), category: @invalid_attrs
      assert html_response(conn, 200) =~ "New category"
    end

    test "shows chosen resource", %{conn: conn} do
      category = Repo.insert! %Category{}
      conn = get conn, category_path(conn, :show, category)
      assert html_response(conn, 200) =~ "Show category"
    end

    test "renders page not found when id is nonexistent", %{conn: conn} do
      assert_error_sent 404, fn ->
        get conn, category_path(conn, :show, -1)
      end
    end

    test "renders form for editing chosen resource", %{conn: conn} do
      category = Repo.insert! %Category{}
      conn = get conn, category_path(conn, :edit, category)
      assert html_response(conn, 200) =~ "Edit category"
    end

    test "updates chosen resource and redirects when data is valid", %{conn: conn} do
      category = Repo.insert! %Category{}
      conn = put conn, category_path(conn, :update, category), category: @valid_attrs
      assert redirected_to(conn) == category_path(conn, :show, category)
      assert Repo.get_by(Category, @valid_attrs)
    end

    test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
      category = Repo.insert! %Category{}
      conn = put conn, category_path(conn, :update, category), category: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit category"
    end

    @tag :currently_broken # FIXME
    test "deletes chosen resource", %{conn: conn} do
      category = Repo.insert! %Category{}
      conn = delete conn, category_path(conn, :delete, category)
      assert redirected_to(conn) == category_path(conn, :index)
      refute Repo.get(Category, category.id)
    end
  end

  test "requires admin authentication on all actions", %{conn: conn} do
    Enum.each([
      get(conn, category_path(conn, :new)),
      get(conn, category_path(conn, :index)),
      get(conn, category_path(conn, :show, "123")),
      get(conn, category_path(conn, :edit, "123")),
      put(conn, category_path(conn, :update, "123")),
      post(conn, category_path(conn, :create, %{})),
      delete(conn, category_path(conn, :delete, "123"))
    ], fn conn ->
      assert html_response(conn, 302)
      assert conn.halted
    end)
  end
end
