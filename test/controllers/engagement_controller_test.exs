defmodule Pan.EngagementControllerTest do
  use PanWeb.ConnCase

  describe "when user is logged in and is an admin" do
    setup do
      admin = insert_admin_user()
      conn = assign(build_conn(), :current_user, admin)
      {:ok, conn: conn}
    end

    alias PanWeb.Engagement

    @valid_attrs %{
      comment: "some content",
      from: %{day: 17, month: 4, year: 2010},
      role: "some content",
      until: %{day: 17, month: 4, year: 2010}
    }
    @invalid_attrs %{}

    test "lists all entries on index", %{conn: conn} do
      conn = get(conn, engagement_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing engagements"
    end

    test "renders form for new resources", %{conn: conn} do
      conn = get(conn, engagement_path(conn, :new))
      assert html_response(conn, 200) =~ "New engagement"
    end

    test "creates resource and redirects when data is valid", %{conn: conn} do
      conn = post(conn, engagement_path(conn, :create), engagement: @valid_attrs)
      assert redirected_to(conn) == engagement_path(conn, :index)
      assert Repo.get_by(Engagement, @valid_attrs)
    end

    test "does not create resource and renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, engagement_path(conn, :create), engagement: @invalid_attrs)
      assert html_response(conn, 200) =~ "New engagement"
    end

    test "shows chosen resource", %{conn: conn} do
      engagement = Repo.insert!(%Engagement{})
      conn = get(conn, engagement_path(conn, :show, engagement))
      assert html_response(conn, 200) =~ "Show engagement"
    end

    test "renders page not found when id is nonexistent", %{conn: conn} do
      assert_error_sent(404, fn ->
        get(conn, engagement_path(conn, :show, -1))
      end)
    end

    test "renders form for editing chosen resource", %{conn: conn} do
      engagement = Repo.insert!(%Engagement{})
      conn = get(conn, engagement_path(conn, :edit, engagement))
      assert html_response(conn, 200) =~ "Edit engagement"
    end

    test "updates chosen resource and redirects when data is valid", %{conn: conn} do
      engagement = Repo.insert!(%Engagement{})
      conn = put(conn, engagement_path(conn, :update, engagement), engagement: @valid_attrs)
      assert redirected_to(conn) == engagement_path(conn, :show, engagement)
      assert Repo.get_by(Engagement, @valid_attrs)
    end

    test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
      engagement = Repo.insert!(%Engagement{})
      conn = put(conn, engagement_path(conn, :update, engagement), engagement: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit engagement"
    end

    test "deletes chosen resource", %{conn: conn} do
      engagement = Repo.insert!(%Engagement{})
      conn = delete(conn, engagement_path(conn, :delete, engagement))
      assert redirected_to(conn) == engagement_path(conn, :index)
      refute Repo.get(Engagement, engagement.id)
    end
  end

  test "requires admin authentication on all actions", %{conn: conn} do
    Enum.each(
      [
        get(conn, engagement_path(conn, :new)),
        get(conn, engagement_path(conn, :index)),
        get(conn, engagement_path(conn, :show, "123")),
        get(conn, engagement_path(conn, :edit, "123")),
        put(conn, engagement_path(conn, :update, "123")),
        post(conn, engagement_path(conn, :create, %{})),
        delete(conn, engagement_path(conn, :delete, "123"))
      ],
      fn conn ->
        assert html_response(conn, 302)
        assert conn.halted
      end
    )
  end
end
