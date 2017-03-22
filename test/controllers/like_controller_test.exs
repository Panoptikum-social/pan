defmodule Pan.LikeControllerTest do
  use Pan.ConnCase

  setup do
    admin = insert_admin_user()
    conn = assign(build_conn(), :current_user, admin)
    {:ok, conn: conn}
  end

  alias Pan.Like
  @valid_attrs %{comment: "some content"}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, like_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing likes"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, like_path(conn, :new)
    assert html_response(conn, 200) =~ "New like"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, like_path(conn, :create), like: @valid_attrs
    assert redirected_to(conn) == like_path(conn, :index)
    assert Repo.get_by(Like, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, like_path(conn, :create), like: @invalid_attrs
    assert html_response(conn, 200) =~ "New like"
  end

  test "shows chosen resource", %{conn: conn} do
    like = Repo.insert! %Like{}
    conn = get conn, like_path(conn, :show, like)
    assert html_response(conn, 200) =~ "Show like"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, like_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    like = Repo.insert! %Like{}
    conn = get conn, like_path(conn, :edit, like)
    assert html_response(conn, 200) =~ "Edit like"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    like = Repo.insert! %Like{}
    conn = put conn, like_path(conn, :update, like), like: @valid_attrs
    assert redirected_to(conn) == like_path(conn, :show, like)
    assert Repo.get_by(Like, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    like = Repo.insert! %Like{}
    conn = put conn, like_path(conn, :update, like), like: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit like"
  end

  test "deletes chosen resource", %{conn: conn} do
    like = Repo.insert! %Like{}
    conn = delete conn, like_path(conn, :delete, like)
    assert redirected_to(conn) == like_path(conn, :index)
    refute Repo.get(Like, like.id)
  end
end
