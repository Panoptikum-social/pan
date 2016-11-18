defmodule Pan.SubscriptionControllerTest do
  use Pan.ConnCase

  alias Pan.Subscription
  @valid_attrs %{}
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
    conn = post conn, subscription_path(conn, :create), subscription: @valid_attrs
    assert redirected_to(conn) == subscription_path(conn, :index)
    assert Repo.get_by(Subscription, @valid_attrs)
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
    subscription = Repo.insert! %Subscription{}
    conn = put conn, subscription_path(conn, :update, subscription), subscription: @valid_attrs
    assert redirected_to(conn) == subscription_path(conn, :show, subscription)
    assert Repo.get_by(Subscription, @valid_attrs)
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
