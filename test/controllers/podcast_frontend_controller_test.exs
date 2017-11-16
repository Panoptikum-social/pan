defmodule Pan.PodcastFrontendControllerTest do
  use PanWeb.ConnCase

  test "lists all entries on index", %{conn: conn} do
    podcast = insert_podcast()

    conn = get conn, podcast_frontend_path(conn, :index)
    assert html_response(conn, 200) =~ "Latest Podcasts"
    assert html_response(conn, 200) =~ podcast.title
  end


  test "lists all entries as buttons", %{conn: conn} do
    podcast = insert_podcast()

    conn = get conn, podcast_frontend_path(conn, :button_index)
    assert html_response(conn, 200) =~ "btn-xs"
    assert html_response(conn, 200) =~ podcast.title
  end


  @tag :currently_broken # FIXME
  test "shows chosen resource", %{conn: conn} do
    podcast = insert_podcast()

    conn = get conn, podcast_frontend_path(conn, :show, podcast)
    assert html_response(conn, 200) =~ podcast.title
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, podcast_frontend_path(conn, :show, -1)
    end
  end


  @tag :currently_broken # FIXME
  test "shows subscribe button for resource", %{conn: conn} do
    podcast = insert_podcast()

    conn = get conn, podcast_frontend_path(conn, :show, podcast)
    assert html_response(conn, 200) =~ "podlove-subscribe-button"
    assert html_response(conn, 200) =~ podcast.title
  end

  test "renders page not found when id is nonexistent for subscribe_button", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, podcast_frontend_path(conn, :subscribe_button, -1)
    end
  end


  test "shows feeds for resource", %{conn: conn} do
    podcast = insert_podcast()
    feed = insert_feed(%{podcast_id: podcast.id})

    conn = get conn, podcast_frontend_path(conn, :feeds, podcast)
    assert html_response(conn, 200) =~ feed.self_link_url
    assert html_response(conn, 200) =~ feed.self_link_title
  end

  test "renders page not found when id is nonexistent for feeds", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, podcast_frontend_path(conn, :feeds, -1)
    end
  end
end
