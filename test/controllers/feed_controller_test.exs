defmodule Pan.FeedControllerTest do
  use PanWeb.ConnCase

  describe "when user is logged in and is an admin" do
    setup do
      admin = insert_admin_user()
      conn = assign(build_conn(), :current_user, admin)
      {:ok, conn: conn}
    end

    alias PanWeb.Feed

    @valid_attrs %{
      feed_generator: "some content",
      first_page_url: "some content",
      hub_link_url: "some content",
      last_page_url: "some content",
      next_page_url: "some content",
      prev_page_url: "some content",
      self_link_title: "some content",
      self_link_url: "some content"
    }
    @invalid_attrs %{}

    test "lists all entries on index", %{conn: conn} do
      conn = get(conn, feed_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing feeds"
    end

    test "renders form for new resources", %{conn: conn} do
      conn = get(conn, feed_path(conn, :new))
      assert html_response(conn, 200) =~ "New feed"
    end

    test "creates resource and redirects when data is valid", %{conn: conn} do
      conn = post(conn, feed_path(conn, :create), feed: @valid_attrs)
      assert redirected_to(conn) == feed_path(conn, :index)
      assert Repo.get_by(Feed, @valid_attrs)
    end

    test "does not create resource and renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, feed_path(conn, :create), feed: @invalid_attrs)
      assert html_response(conn, 200) =~ "New feed"
    end

    test "shows chosen resource", %{conn: conn} do
      feed = Repo.insert!(%Feed{})
      conn = get(conn, feed_path(conn, :show, feed))
      assert html_response(conn, 200) =~ "Show feed"
    end

    test "renders page not found when id is nonexistent", %{conn: conn} do
      assert_error_sent(404, fn ->
        get(conn, feed_path(conn, :show, -1))
      end)
    end

    test "renders form for editing chosen resource", %{conn: conn} do
      feed = Repo.insert!(%Feed{})
      conn = get(conn, feed_path(conn, :edit, feed))
      assert html_response(conn, 200) =~ "Edit feed"
    end

    test "updates chosen resource and redirects when data is valid", %{conn: conn} do
      feed = Repo.insert!(%Feed{})
      conn = put(conn, feed_path(conn, :update, feed), feed: @valid_attrs)
      assert redirected_to(conn) == feed_path(conn, :show, feed)
      assert Repo.get_by(Feed, @valid_attrs)
    end

    test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
      feed = Repo.insert!(%Feed{})
      conn = put(conn, feed_path(conn, :update, feed), feed: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit feed"
    end

    test "deletes chosen resource", %{conn: conn} do
      feed = Repo.insert!(%Feed{})
      conn = delete(conn, feed_path(conn, :delete, feed))
      assert redirected_to(conn) == feed_path(conn, :index)
      refute Repo.get(Feed, feed.id)
    end
  end

  test "requires admin authentication on all actions", %{conn: conn} do
    Enum.each(
      [
        get(conn, feed_path(conn, :new)),
        get(conn, feed_path(conn, :index)),
        get(conn, feed_path(conn, :show, "123")),
        get(conn, feed_path(conn, :edit, "123")),
        put(conn, feed_path(conn, :update, "123")),
        post(conn, feed_path(conn, :create, %{})),
        delete(conn, feed_path(conn, :delete, "123"))
      ],
      fn conn ->
        assert html_response(conn, 302)
        assert conn.halted
      end
    )
  end
end
