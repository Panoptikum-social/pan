defmodule Pan.GigControllerTest do
  use Pan.ConnCase

  setup do
    admin = insert_admin_user()
    conn = assign(build_conn(), :current_user, admin)
    {:ok, conn: conn}
  end

  alias Pan.Gig
  @valid_attrs %{comment: "some content", from_in_s: 42, publishing_date: %{day: 17, hour: 14, min: 0, month: 4, sec: 0, year: 2010}, role: "some content", until_in_s: 42}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, gig_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing gigs"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, gig_path(conn, :new)
    assert html_response(conn, 200) =~ "New gig"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, gig_path(conn, :create), gig: @valid_attrs
    assert redirected_to(conn) == gig_path(conn, :index)
    assert Repo.get_by(Gig, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, gig_path(conn, :create), gig: @invalid_attrs
    assert html_response(conn, 200) =~ "New gig"
  end

  test "shows chosen resource", %{conn: conn} do
    gig = Repo.insert! %Gig{}
    conn = get conn, gig_path(conn, :show, gig)
    assert html_response(conn, 200) =~ "Show gig"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, gig_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    gig = Repo.insert! %Gig{}
    conn = get conn, gig_path(conn, :edit, gig)
    assert html_response(conn, 200) =~ "Edit gig"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    gig = Repo.insert! %Gig{}
    conn = put conn, gig_path(conn, :update, gig), gig: @valid_attrs
    assert redirected_to(conn) == gig_path(conn, :show, gig)
    assert Repo.get_by(Gig, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    gig = Repo.insert! %Gig{}
    conn = put conn, gig_path(conn, :update, gig), gig: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit gig"
  end

  test "deletes chosen resource", %{conn: conn} do
    gig = Repo.insert! %Gig{}
    conn = delete conn, gig_path(conn, :delete, gig)
    assert redirected_to(conn) == gig_path(conn, :index)
    refute Repo.get(Gig, gig.id)
  end
end
