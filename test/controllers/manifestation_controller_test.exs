defmodule Pan.ManifestationControllerTest do
  use Pan.ConnCase

  alias Pan.Manifestation
  @valid_attrs %{}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, manifestation_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing manifestations"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, manifestation_path(conn, :new)
    assert html_response(conn, 200) =~ "New manifestation"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, manifestation_path(conn, :create), manifestation: @valid_attrs
    assert redirected_to(conn) == manifestation_path(conn, :index)
    assert Repo.get_by(Manifestation, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, manifestation_path(conn, :create), manifestation: @invalid_attrs
    assert html_response(conn, 200) =~ "New manifestation"
  end

  test "shows chosen resource", %{conn: conn} do
    manifestation = Repo.insert! %Manifestation{}
    conn = get conn, manifestation_path(conn, :show, manifestation)
    assert html_response(conn, 200) =~ "Show manifestation"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, manifestation_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    manifestation = Repo.insert! %Manifestation{}
    conn = get conn, manifestation_path(conn, :edit, manifestation)
    assert html_response(conn, 200) =~ "Edit manifestation"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    manifestation = Repo.insert! %Manifestation{}
    conn = put conn, manifestation_path(conn, :update, manifestation), manifestation: @valid_attrs
    assert redirected_to(conn) == manifestation_path(conn, :show, manifestation)
    assert Repo.get_by(Manifestation, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    manifestation = Repo.insert! %Manifestation{}
    conn = put conn, manifestation_path(conn, :update, manifestation), manifestation: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit manifestation"
  end

  test "deletes chosen resource", %{conn: conn} do
    manifestation = Repo.insert! %Manifestation{}
    conn = delete conn, manifestation_path(conn, :delete, manifestation)
    assert redirected_to(conn) == manifestation_path(conn, :index)
    refute Repo.get(Manifestation, manifestation.id)
  end
end
