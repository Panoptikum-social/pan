defmodule Pan.UserControllerTest do
  use PanWeb.ConnCase

  describe "when user is logged in and is an admin" do
    setup do
      admin = insert_admin_user()
      conn = assign(build_conn(), :current_user, admin)
      {:ok, conn: conn}
    end

    alias PanWeb.User
    @valid_attrs %{name: "John Doe",
                   username: "jdoe" ,
                   email: "john.doe@panoptikum.io",
                   admin: false,
                   podcaster: false}
    @invalid_attrs %{name: nil}

    test "lists all entries on index", %{conn: conn} do
      conn = get conn, user_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing Users"
    end

    test "shows chosen resource", %{conn: conn} do
      user = %User{}
             |> Map.merge(@valid_attrs)
             |> Repo.insert!
      conn = get conn, user_path(conn, :show, user)
      assert html_response(conn, 200) =~ "Showing User"
    end

    test "renders page not found when id is nonexistent", %{conn: conn} do
      assert_error_sent 404, fn ->
        get conn, user_path(conn, :show, -1)
      end
    end

    test "renders form for editing chosen resource", %{conn: conn} do
      user = User.changeset(%User{}, @valid_attrs)
             |> Repo.insert!
      conn = get conn, user_path(conn, :edit, user)
      assert html_response(conn, 200) =~ "Edit user"
    end

    test "updates chosen resource and redirects when data is valid", %{conn: conn} do
      user = User.changeset(%User{}, @valid_attrs)
             |> Repo.insert!
      conn = put conn, user_path(conn, :update, user), user: @valid_attrs

      assert redirected_to(conn) == user_path(conn, :show, user)
      assert Repo.get_by(User, @valid_attrs)
    end

    test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
      user = User.changeset(%User{}, @valid_attrs)
             |> Repo.insert!
      conn = put conn, user_path(conn, :update, user), user: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit user"
    end

    test "deletes chosen resource", %{conn: conn} do
      user = User.changeset(%User{}, @valid_attrs)
             |> Repo.insert!
      conn = delete conn, user_path(conn, :delete, user)
      assert redirected_to(conn) == user_path(conn, :index)
      refute Repo.get(User, user.id)
    end
  end

  test "requires admin authentication on all actions", %{conn: conn} do
    Enum.each([
      get(conn, user_path(conn, :new)),
      get(conn, user_path(conn, :index)),
      get(conn, user_path(conn, :show, "123")),
      get(conn, user_path(conn, :edit, "123")),
      put(conn, user_path(conn, :update, "123")),
      post(conn, user_path(conn, :create, %{})),
      delete(conn, user_path(conn, :delete, "123"))
    ], fn conn ->
      assert html_response(conn, 302)
      assert conn.halted
    end)
  end
end