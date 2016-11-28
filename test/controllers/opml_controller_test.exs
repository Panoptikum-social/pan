defmodule Pan.OPMLControllerTest do
  use Pan.ConnCase

  alias Pan.OPML
  @valid_attrs %{content_type: "some content", filename: "some content", path: "some content"}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, opml_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing opmls"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, opml_path(conn, :new)
    assert html_response(conn, 200) =~ "New opml"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, opml_path(conn, :create), opml: @valid_attrs
    assert redirected_to(conn) == opml_path(conn, :index)
    assert Repo.get_by(OPML, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, opml_path(conn, :create), opml: @invalid_attrs
    assert html_response(conn, 200) =~ "New opml"
  end

  test "shows chosen resource", %{conn: conn} do
    opml = Repo.insert! %OPML{}
    conn = get conn, opml_path(conn, :show, opml)
    assert html_response(conn, 200) =~ "Show opml"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, opml_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    opml = Repo.insert! %OPML{}
    conn = get conn, opml_path(conn, :edit, opml)
    assert html_response(conn, 200) =~ "Edit opml"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    opml = Repo.insert! %OPML{}
    conn = put conn, opml_path(conn, :update, opml), opml: @valid_attrs
    assert redirected_to(conn) == opml_path(conn, :show, opml)
    assert Repo.get_by(OPML, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    opml = Repo.insert! %OPML{}
    conn = put conn, opml_path(conn, :update, opml), opml: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit opml"
  end

  test "deletes chosen resource", %{conn: conn} do
    opml = Repo.insert! %OPML{}
    conn = delete conn, opml_path(conn, :delete, opml)
    assert redirected_to(conn) == opml_path(conn, :index)
    refute Repo.get(OPML, opml.id)
  end
end
