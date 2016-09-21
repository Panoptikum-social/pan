defmodule Pan.ContributorControllerTest do
  use Pan.ConnCase

  alias Pan.Contributor
  @valid_attrs %{name: "some content", uri: "some content"}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, contributor_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing contributors"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, contributor_path(conn, :new)
    assert html_response(conn, 200) =~ "New contributor"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, contributor_path(conn, :create), contributor: @valid_attrs
    assert redirected_to(conn) == contributor_path(conn, :index)
    assert Repo.get_by(Contributor, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, contributor_path(conn, :create), contributor: @invalid_attrs
    assert html_response(conn, 200) =~ "New contributor"
  end

  test "shows chosen resource", %{conn: conn} do
    contributor = Repo.insert! %Contributor{}
    conn = get conn, contributor_path(conn, :show, contributor)
    assert html_response(conn, 200) =~ "Show contributor"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, contributor_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    contributor = Repo.insert! %Contributor{}
    conn = get conn, contributor_path(conn, :edit, contributor)
    assert html_response(conn, 200) =~ "Edit contributor"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    contributor = Repo.insert! %Contributor{}
    conn = put conn, contributor_path(conn, :update, contributor), contributor: @valid_attrs
    assert redirected_to(conn) == contributor_path(conn, :show, contributor)
    assert Repo.get_by(Contributor, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    contributor = Repo.insert! %Contributor{}
    conn = put conn, contributor_path(conn, :update, contributor), contributor: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit contributor"
  end

  test "deletes chosen resource", %{conn: conn} do
    contributor = Repo.insert! %Contributor{}
    conn = delete conn, contributor_path(conn, :delete, contributor)
    assert redirected_to(conn) == contributor_path(conn, :index)
    refute Repo.get(Contributor, contributor.id)
  end
end
