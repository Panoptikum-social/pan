defmodule Pan.SubscriptionControllerTest do
  use Pan.ConnCase

  describe "when user is logged in and is an admin" do
    setup do
      admin = insert_admin_user()
      conn = assign(build_conn(), :current_user, admin)
      {:ok, conn: conn}
    end

    alias Pan.Subscription
    @invalid_attrs %{}

    test "lists all entries on index", %{conn: conn} do
      conn = get conn, subscription_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing subscriptions"
    end

    test "renders form for new resources", %{conn: conn} do
      conn = get conn, subscription_path(conn, :new)
      assert html_response(conn, 200) =~ "New subscription"
    end

    test "creates resource and redirects when data is valid", %{conn: conn} do
      user = insert_user()
      podcast = insert_podcast()

      conn = post conn, subscription_path(conn, :create),
                        subscription: %{user_id: user.id,
                                        podcast_id: podcast.id}
      assert redirected_to(conn) == subscription_path(conn, :index)
      assert Repo.get_by(Subscription, %{user_id: user.id,
                                         podcast_id: podcast.id})
    end

    test "does not create resource and renders errors when data is invalid", %{conn: conn} do
      conn = post conn, subscription_path(conn, :create), subscription: @invalid_attrs
      assert html_response(conn, 200) =~ "New subscription"
    end

    test "shows chosen resource", %{conn: conn} do
      subscription = Repo.insert! %Subscription{}
      conn = get conn, subscription_path(conn, :show, subscription)
      assert html_response(conn, 200) =~ "Show subscription"
    end

    test "renders page not found when id is nonexistent", %{conn: conn} do
      assert_error_sent 404, fn ->
        get conn, subscription_path(conn, :show, -1)
      end
    end

    test "renders form for editing chosen resource", %{conn: conn} do
      subscription = Repo.insert! %Subscription{}
      conn = get conn, subscription_path(conn, :edit, subscription)
      assert html_response(conn, 200) =~ "Edit subscription"
    end

    test "updates chosen resource and redirects when data is valid", %{conn: conn} do
      user = insert_user()
      podcast = insert_podcast()

      subscription = Repo.insert! %Subscription{}
      conn = put conn, subscription_path(conn, :update, subscription),
                       subscription: %{user_id: user.id,
                                       podcast_id: podcast.id}
      assert redirected_to(conn) == subscription_path(conn, :show, subscription)
      assert Repo.get_by(Subscription, %{user_id: user.id,
                                         podcast_id: podcast.id})
    end

    test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
      subscription = Repo.insert! %Subscription{}
      conn = put conn, subscription_path(conn, :update, subscription), subscription: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit subscription"
    end

    test "deletes chosen resource", %{conn: conn} do
      subscription = Repo.insert! %Subscription{}
      conn = delete conn, subscription_path(conn, :delete, subscription)
      assert redirected_to(conn) == subscription_path(conn, :index)
      refute Repo.get(Subscription, subscription.id)
    end
  end

  test "requires admin authentication on all actions", %{conn: conn} do
    Enum.each([
      get(conn, subscription_path(conn, :new)),
      get(conn, subscription_path(conn, :index)),
      get(conn, subscription_path(conn, :show, "123")),
      get(conn, subscription_path(conn, :edit, "123")),
      put(conn, subscription_path(conn, :update, "123")),
      post(conn, subscription_path(conn, :create, %{})),
      delete(conn, subscription_path(conn, :delete, "123"))
    ], fn conn ->
      assert html_response(conn, 302)
      assert conn.halted
    end)
  end
end