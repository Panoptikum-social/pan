defmodule Pan.EpisodeFrontendControllerTest do
  use PanWeb.ConnCase

  test "lists all entries on index", %{conn: conn} do
    podcast = insert_podcast()
    episode = insert_episode(%{podcast_id: podcast.id})

    conn = get(conn, episode_frontend_path(conn, :index))
    assert html_response(conn, 200) =~ "Latest episodes"
    assert html_response(conn, 200) =~ episode.title
  end

  test "shows chosen resource", %{conn: conn} do
    podcast = insert_podcast()
    episode = insert_episode(%{podcast_id: podcast.id})

    conn = get(conn, episode_frontend_path(conn, :show, episode))
    assert html_response(conn, 200) =~ episode.title
  end

  test "shows player for chosen resource", %{conn: conn} do
    podcast = insert_podcast()
    episode = insert_episode(%{podcast_id: podcast.id})

    conn = get(conn, episode_frontend_path(conn, :player, episode))
    assert html_response(conn, 200) =~ "playerConfiguration"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent(404, fn ->
      get(conn, episode_frontend_path(conn, :show, -1))
    end)
  end
end
