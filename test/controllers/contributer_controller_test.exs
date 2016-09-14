defmodule Pan.ContributerControllerTest do
  use Pan.ConnCase

  alias Pan.Contributer
  @valid_attrs %{name: "some content", uri: "some content"}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, contributer_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing contributers"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, contributer_path(conn, :new)
    assert html_response(conn, 200) =~ "New contributer"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, contributer_path(conn, :create), contributer: @valid_attrs
    assert redirected_to(conn) == contributer_path(conn, :index)
    assert Repo.get_by(Contributer, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, contributer_path(conn, :create), contributer: @invalid_attrs
    assert html_response(conn, 200) =~ "New contributer"
  end

  test "shows chosen resource", %{conn: conn} do
    contributer = Repo.insert! %Contributer{}
    conn = get conn, contributer_path(conn, :show, contributer)
    assert html_response(conn, 200) =~ "Show contributer"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, contributer_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    contributer = Repo.insert! %Contributer{}
    conn = get conn, contributer_path(conn, :edit, contributer)
    assert html_response(conn, 200) =~ "Edit contributer"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    contributer = Repo.insert! %Contributer{}
    conn = put conn, contributer_path(conn, :update, contributer), contributer: @valid_attrs
    assert redirected_to(conn) == contributer_path(conn, :show, contributer)
    assert Repo.get_by(Contributer, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    contributer = Repo.insert! %Contributer{}
    conn = put conn, contributer_path(conn, :update, contributer), contributer: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit contributer"
  end

  test "deletes chosen resource", %{conn: conn} do
    contributer = Repo.insert! %Contributer{}
    conn = delete conn, contributer_path(conn, :delete, contributer)
    assert redirected_to(conn) == contributer_path(conn, :index)
    refute Repo.get(Contributer, contributer.id)
  end
end
