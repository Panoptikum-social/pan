defmodule Pan.SubscriptionControllerTest do
  use Pan.ConnCase

  setup do
    admin = insert_admin_user()
    user = insert_user()
    podcast = insert_podcast()
    conn = assign(build_conn(), :current_user, admin)
    {:ok, conn: conn, user_id: user.id, podcast_id: podcast.id}
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

  test "creates resource and redirects when data is valid", %{conn: conn,
                                                              user_id: user_id,
                                                              podcast_id: podcast_id} do
    conn = post conn, subscription_path(conn, :create),
                      subscription: %{user_id: user_id,
                                      podcast_id: podcast_id}
    assert redirected_to(conn) == subscription_path(conn, :index)
    assert Repo.get_by(Subscription, %{user_id: user_id,
                                       podcast_id: podcast_id})
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

  test "updates chosen resource and redirects when data is valid", %{conn: conn,
                                                                     user_id: user_id,
                                                                     podcast_id: podcast_id} do
    subscription = Repo.insert! %Subscription{}
    conn = put conn, subscription_path(conn, :update, subscription),
                     subscription: %{user_id: user_id,
                                     podcast_id: podcast_id}
    assert redirected_to(conn) == subscription_path(conn, :show, subscription)
    assert Repo.get_by(Subscription, %{user_id: user_id,
                                       podcast_id: podcast_id})
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
