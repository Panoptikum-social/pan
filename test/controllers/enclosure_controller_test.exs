defmodule Pan.EnclosureControllerTest do
  use PanWeb.ConnCase

  describe "when user is logged in and is an admin" do
    setup do
      admin = insert_admin_user()
      conn = assign(build_conn(), :current_user, admin)
      {:ok, conn: conn}
    end

    alias PanWeb.Enclosure
    @valid_attrs %{guid: "some content", length: "some content", type: "some content", url: "some content"}
    @invalid_attrs %{}

    test "lists all entries on index", %{conn: conn} do
      conn = get conn, enclosure_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing enclosures"
    end

    test "renders form for new resources", %{conn: conn} do
      conn = get conn, enclosure_path(conn, :new)
      assert html_response(conn, 200) =~ "New enclosure"
    end

    test "creates resource and redirects when data is valid", %{conn: conn} do
      conn = post conn, enclosure_path(conn, :create), enclosure: @valid_attrs
      assert redirected_to(conn) == enclosure_path(conn, :index)
      assert Repo.get_by(Enclosure, @valid_attrs)
    end

    test "does not create resource and renders errors when data is invalid", %{conn: conn} do
      conn = post conn, enclosure_path(conn, :create), enclosure: @invalid_attrs
      assert html_response(conn, 200) =~ "New enclosure"
    end

    test "shows chosen resource", %{conn: conn} do
      enclosure = Repo.insert! %Enclosure{}
      conn = get conn, enclosure_path(conn, :show, enclosure)
      assert html_response(conn, 200) =~ "Show enclosure"
    end

    test "renders page not found when id is nonexistent", %{conn: conn} do
      assert_error_sent 404, fn ->
        get conn, enclosure_path(conn, :show, -1)
      end
    end

    test "renders form for editing chosen resource", %{conn: conn} do
      enclosure = Repo.insert! %Enclosure{}
      conn = get conn, enclosure_path(conn, :edit, enclosure)
      assert html_response(conn, 200) =~ "Edit enclosure"
    end

    test "updates chosen resource and redirects when data is valid", %{conn: conn} do
      enclosure = Repo.insert! %Enclosure{}
      conn = put conn, enclosure_path(conn, :update, enclosure), enclosure: @valid_attrs
      assert redirected_to(conn) == enclosure_path(conn, :show, enclosure)
      assert Repo.get_by(Enclosure, @valid_attrs)
    end

    test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
      enclosure = Repo.insert! %Enclosure{}
      conn = put conn, enclosure_path(conn, :update, enclosure), enclosure: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit enclosure"
    end

    test "deletes chosen resource", %{conn: conn} do
      enclosure = Repo.insert! %Enclosure{}
      conn = delete conn, enclosure_path(conn, :delete, enclosure)
      assert redirected_to(conn) == enclosure_path(conn, :index)
      refute Repo.get(Enclosure, enclosure.id)
    end
  end

  test "requires admin authentication on all actions", %{conn: conn} do
    Enum.each([
      get(conn, enclosure_path(conn, :new)),
      get(conn, enclosure_path(conn, :index)),
      get(conn, enclosure_path(conn, :show, "123")),
      get(conn, enclosure_path(conn, :edit, "123")),
      put(conn, enclosure_path(conn, :update, "123")),
      post(conn, enclosure_path(conn, :create, %{})),
      delete(conn, enclosure_path(conn, :delete, "123"))
    ], fn conn ->
      assert html_response(conn, 302)
      assert conn.halted
    end)
  end
end