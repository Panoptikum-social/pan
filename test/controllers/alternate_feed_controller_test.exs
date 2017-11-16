defmodule Pan.AlternateFeedControllerTest do
  use PanWeb.ConnCase
  alias PanWeb.AlternateFeed
  @valid_attrs %{title: "some content", url: "some content"}
  @invalid_attrs %{}

  describe "when user is logged in and is an admin" do
    setup do
      admin = insert_admin_user()
      conn = assign(build_conn(), :current_user, admin)
      {:ok, conn: conn}
    end

    test "lists all entries on index", %{conn: conn} do
      conn = get conn, alternate_feed_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing alternate feeds"
    end

    test "renders form for new resources", %{conn: conn} do
      conn = get conn, alternate_feed_path(conn, :new)
      assert html_response(conn, 200) =~ "New alternate feed"
    end

    test "creates resource and redirects when data is valid", %{conn: conn} do
      conn = post conn, alternate_feed_path(conn, :create), alternate_feed: @valid_attrs
      assert redirected_to(conn) == alternate_feed_path(conn, :index)
      assert Repo.get_by(AlternateFeed, @valid_attrs)
    end

    test "does not create resource and renders errors when data is invalid", %{conn: conn} do
      conn = post conn, alternate_feed_path(conn, :create), alternate_feed: @invalid_attrs
      assert html_response(conn, 200) =~ "New alternate feed"
    end

    test "shows chosen resource", %{conn: conn} do
      alternate_feed = Repo.insert! %AlternateFeed{}
      conn = get conn, alternate_feed_path(conn, :show, alternate_feed)
      assert html_response(conn, 200) =~ "Show alternate feed"
    end

    test "renders page not found when id is nonexistent", %{conn: conn} do
      assert_error_sent 404, fn ->
        get conn, alternate_feed_path(conn, :show, -1)
      end
    end

    test "renders form for editing chosen resource", %{conn: conn} do
      alternate_feed = Repo.insert! %AlternateFeed{}
      conn = get conn, alternate_feed_path(conn, :edit, alternate_feed)
      assert html_response(conn, 200) =~ "Edit alternate feed"
    end

    test "updates chosen resource and redirects when data is valid", %{conn: conn} do
      alternate_feed = Repo.insert! %AlternateFeed{}
      conn = put conn, alternate_feed_path(conn, :update, alternate_feed), alternate_feed: @valid_attrs
      assert redirected_to(conn) == alternate_feed_path(conn, :show, alternate_feed)
      assert Repo.get_by(AlternateFeed, @valid_attrs)
    end

    test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
      alternate_feed = Repo.insert! %AlternateFeed{}
      conn = put conn, alternate_feed_path(conn, :update, alternate_feed), alternate_feed: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit alternate feed"
    end

    @tag :currently_broken # FIXME
    test "deletes chosen resource", %{conn: conn} do
      alternate_feed = Repo.insert! %AlternateFeed{}
      conn = delete conn, alternate_feed_path(conn, :delete, alternate_feed)
      assert redirected_to(conn) == alternate_feed_path(conn, :index)
      refute Repo.get(AlternateFeed, alternate_feed.id)
    end
  end

  test "requires admin authentication on all actions", %{conn: conn} do
    Enum.each([
      get(conn, alternate_feed_path(conn, :new)),
      get(conn, alternate_feed_path(conn, :index)),
      get(conn, alternate_feed_path(conn, :show, "123")),
      get(conn, alternate_feed_path(conn, :edit, "123")),
      put(conn, alternate_feed_path(conn, :update, "123")),
      post(conn, alternate_feed_path(conn, :create, %{})),
      delete(conn, alternate_feed_path(conn, :delete, "123"))
    ], fn conn ->
      assert html_response(conn, 302)
      assert conn.halted
    end)
  end
end
