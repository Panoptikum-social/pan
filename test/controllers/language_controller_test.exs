defmodule Pan.LanguageControllerTest do
  use PanWeb.ConnCase

  describe "when user is logged in and is an admin" do
    setup do
      admin = insert_admin_user()
      conn = assign(build_conn(), :current_user, admin)
      {:ok, conn: conn}
    end

    alias PanWeb.Language
    @valid_attrs %{name: "some content", shortcode: "some content"}
    @invalid_attrs %{}

    test "lists all entries on index", %{conn: conn} do
      conn = get conn, language_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing languages"
    end

    test "renders form for new resources", %{conn: conn} do
      conn = get conn, language_path(conn, :new)
      assert html_response(conn, 200) =~ "New language"
    end

    test "creates resource and redirects when data is valid", %{conn: conn} do
      conn = post conn, language_path(conn, :create), language: @valid_attrs
      assert redirected_to(conn) == language_path(conn, :index)
      assert Repo.get_by(Language, @valid_attrs)
    end

    test "does not create resource and renders errors when data is invalid", %{conn: conn} do
      conn = post conn, language_path(conn, :create), language: @invalid_attrs
      assert html_response(conn, 200) =~ "New language"
    end

    test "shows chosen resource", %{conn: conn} do
      language = Repo.insert! %Language{}
      conn = get conn, language_path(conn, :show, language)
      assert html_response(conn, 200) =~ "Show language"
    end

    test "renders page not found when id is nonexistent", %{conn: conn} do
      assert_error_sent 404, fn ->
        get conn, language_path(conn, :show, -1)
      end
    end

    test "renders form for editing chosen resource", %{conn: conn} do
      language = Repo.insert! %Language{}
      conn = get conn, language_path(conn, :edit, language)
      assert html_response(conn, 200) =~ "Edit language"
    end

    test "updates chosen resource and redirects when data is valid", %{conn: conn} do
      language = Repo.insert! %Language{}
      conn = put conn, language_path(conn, :update, language), language: @valid_attrs
      assert redirected_to(conn) == language_path(conn, :show, language)
      assert Repo.get_by(Language, @valid_attrs)
    end

    test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
      language = Repo.insert! %Language{}
      conn = put conn, language_path(conn, :update, language), language: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit language"
    end

    test "deletes chosen resource", %{conn: conn} do
      language = Repo.insert! %Language{}
      conn = delete conn, language_path(conn, :delete, language)
      assert redirected_to(conn) == language_path(conn, :index)
      refute Repo.get(Language, language.id)
    end
  end

  test "requires admin authentication on all actions", %{conn: conn} do
    Enum.each([
      get(conn, language_path(conn, :new)),
      get(conn, language_path(conn, :index)),
      get(conn, language_path(conn, :show, "123")),
      get(conn, language_path(conn, :edit, "123")),
      put(conn, language_path(conn, :update, "123")),
      post(conn, language_path(conn, :create, %{})),
      delete(conn, language_path(conn, :delete, "123"))
    ], fn conn ->
      assert html_response(conn, 302)
      assert conn.halted
    end)
  end
end