defmodule Pan.FeedBacklogControllerTest do
  use PanWeb.ConnCase

  describe "when user is logged in and is an admin" do
    setup do
      admin = insert_admin_user()
      conn = assign(build_conn(), :current_user, admin)
      {:ok, conn: conn}
    end

    alias PanWeb.FeedBacklog

    @valid_attrs %{
      feed_generator: "some content",
      in_progress: true,
      url: "http://panopkikum.io/dir/file.rss"
    }
    @invalid_attrs %{}

    test "lists all entries on index", %{conn: conn} do
      conn = get(conn, feed_backlog_path(conn, :index))
      assert html_response(conn, 200) =~ "backlog feeds"
    end

    test "renders form for new resources", %{conn: conn} do
      conn = get(conn, feed_backlog_path(conn, :new))
      assert html_response(conn, 200) =~ "New feed backlog"
    end

    test "creates resource and redirects when data is valid", %{conn: conn} do
      conn = post(conn, feed_backlog_path(conn, :create), feed_backlog: @valid_attrs)
      assert redirected_to(conn) == feed_backlog_path(conn, :index)
      assert Repo.get_by(FeedBacklog, @valid_attrs)
    end

    test "does not create resource and renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, feed_backlog_path(conn, :create), feed_backlog: @invalid_attrs)
      assert html_response(conn, 200) =~ "New feed backlog"
    end

    test "shows chosen resource", %{conn: conn} do
      feed_backlog = Repo.insert!(Map.merge(%FeedBacklog{}, @valid_attrs))
      conn = get(conn, feed_backlog_path(conn, :show, feed_backlog))
      assert html_response(conn, 200) =~ "Show feed backlog"
    end

    test "renders page not found when id is nonexistent", %{conn: conn} do
      assert_error_sent(404, fn ->
        get(conn, feed_backlog_path(conn, :show, -1))
      end)
    end

    test "renders form for editing chosen resource", %{conn: conn} do
      feed_backlog = Repo.insert!(%FeedBacklog{})
      conn = get(conn, feed_backlog_path(conn, :edit, feed_backlog))
      assert html_response(conn, 200) =~ "Edit feed backlog"
    end

    test "updates chosen resource and redirects when data is valid", %{conn: conn} do
      feed_backlog = Repo.insert!(%FeedBacklog{})
      conn = put(conn, feed_backlog_path(conn, :update, feed_backlog), feed_backlog: @valid_attrs)
      assert redirected_to(conn) == feed_backlog_path(conn, :show, feed_backlog)
      assert Repo.get_by(FeedBacklog, @valid_attrs)
    end

    test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
      feed_backlog = Repo.insert!(%FeedBacklog{})

      conn =
        put(conn, feed_backlog_path(conn, :update, feed_backlog), feed_backlog: @invalid_attrs)

      assert html_response(conn, 200) =~ "Edit feed backlog"
    end

    test "deletes chosen resource", %{conn: conn} do
      feed_backlog = Repo.insert!(%FeedBacklog{})
      conn = delete(conn, feed_backlog_path(conn, :delete, feed_backlog))
      assert redirected_to(conn) == feed_backlog_path(conn, :index)
      refute Repo.get(FeedBacklog, feed_backlog.id)
    end
  end

  test "requires admin authentication on all actions", %{conn: conn} do
    Enum.each(
      [
        get(conn, feed_backlog_path(conn, :new)),
        get(conn, feed_backlog_path(conn, :index)),
        get(conn, feed_backlog_path(conn, :show, "123")),
        get(conn, feed_backlog_path(conn, :edit, "123")),
        put(conn, feed_backlog_path(conn, :update, "123")),
        post(conn, feed_backlog_path(conn, :create, %{})),
        delete(conn, feed_backlog_path(conn, :delete, "123"))
      ],
      fn conn ->
        assert html_response(conn, 302)
        assert conn.halted
      end
    )
  end
end
