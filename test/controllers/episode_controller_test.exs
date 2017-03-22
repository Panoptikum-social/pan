defmodule Pan.EpisodeControllerTest do
  use Pan.ConnCase

  setup do
    admin = insert_admin_user()
    conn = assign(build_conn(), :current_user, admin)
    {:ok, conn: conn}
  end

  alias Pan.Episode
  @valid_attrs %{author: "some content", deep_link: "some content", description: "some content", duration: "some content", guid: "some content", link: "some content", payment_link_title: "some content", payment_link_url: "some content", publishing_date: "2010-04-17 14:00:00", shownotes: "some content", subtitle: "some content", summary: "some content", title: "some content"}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, episode_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing episodes"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, episode_path(conn, :new)
    assert html_response(conn, 200) =~ "New episode"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, episode_path(conn, :create), episode: @valid_attrs
    assert redirected_to(conn) == episode_path(conn, :index)
    assert Repo.get_by(Episode, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, episode_path(conn, :create), episode: @invalid_attrs
    assert html_response(conn, 200) =~ "New episode"
  end

  test "shows chosen resource", %{conn: conn} do
    episode = Repo.insert! %Episode{}
    conn = get conn, episode_path(conn, :show, episode)
    assert html_response(conn, 200) =~ "Show episode"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, episode_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    episode = Repo.insert! %Episode{}
    conn = get conn, episode_path(conn, :edit, episode)
    assert html_response(conn, 200) =~ "Edit episode"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    episode = Repo.insert! %Episode{}
    conn = put conn, episode_path(conn, :update, episode), episode: @valid_attrs
    assert redirected_to(conn) == episode_path(conn, :show, episode)
    assert Repo.get_by(Episode, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    episode = Repo.insert! %Episode{}
    conn = put conn, episode_path(conn, :update, episode), episode: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit episode"
  end

  test "deletes chosen resource", %{conn: conn} do
    episode = Repo.insert! %Episode{}
    conn = delete conn, episode_path(conn, :delete, episode)
    assert redirected_to(conn) == episode_path(conn, :index)
    refute Repo.get(Episode, episode.id)
  end
end
