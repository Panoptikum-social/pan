defmodule Pan.RecommendationFrontendControllerTest do
  use PanWeb.ConnCase
  alias PanWeb.Recommendation
  alias PanWeb.Message

  test "lists all entries on index", %{conn: conn} do
    user = insert_user()
    podcast = insert_podcast()
    recommendation = insert_recommendation(%{user_id: user.id, podcast_id: podcast.id})

    conn = get(conn, recommendation_frontend_path(conn, :index))
    assert html_response(conn, 200) =~ recommendation.comment
  end

  test "lists my_recommendations", %{conn: conn} do
    user = insert_user()
    podcast = insert_podcast()
    recommendation = insert_recommendation(%{user_id: user.id, podcast_id: podcast.id})

    another_user =
      insert_user(%{name: "Another User", username: "auser", email: "another.user@panoptikum.io"})

    another_recommendation =
      insert_recommendation(%{
        user_id: another_user.id,
        podcast_id: podcast.id,
        comment: "a different comment text"
      })

    conn = assign(conn, :current_user, user)

    conn = get(conn, recommendation_frontend_path(conn, :my_recommendations))
    assert html_response(conn, 200) =~ recommendation.comment
    refute html_response(conn, 200) =~ another_recommendation.comment
  end

  # FIXME
  @tag :currently_broken
  test "shows a random podcast, episode and category on random", %{conn: conn} do
    category = insert_category()
    podcast = insert_podcast()
    assign_podcast_to_category(podcast, category)
    episode = insert_episode(%{podcast_id: podcast.id})

    conn = get(conn, recommendation_frontend_path(conn, :random))
    assert html_response(conn, 200) =~ category.title
    assert html_response(conn, 200) =~ podcast.title
    assert html_response(conn, 200) =~ episode.title
  end

  test "can create a podcast recommendation, a message and redirects back", %{conn: conn} do
    user = insert_user()
    podcast = insert_podcast()

    conn =
      assign(conn, :current_user, user)
      |> Plug.Conn.put_req_header("referer", "/podcasts/" <> Integer.to_string(podcast.id))
      |> post(
        recommendation_frontend_path(conn, :create, %{
          recommendation: %{podcast_id: podcast.id, comment: "recommendation comment"}
        })
      )

    assert redirected_to(conn) == podcast_frontend_path(conn, :show, podcast)

    assert Repo.get_by(Recommendation, %{
             podcast_id: podcast.id,
             user_id: user.id,
             comment: "recommendation comment"
           })

    assert Repo.get_by(Message, %{
             topic: "podcasts",
             subtopic: Integer.to_string(podcast.id),
             event: "recommend",
             type: "success",
             creator_id: user.id
           })
  end

  # FIXME
  @tag :currently_broken
  test "can create an episode recommendation, a message and redirects back", %{conn: conn} do
    user = insert_user()
    podcast = insert_podcast()
    episode = insert_episode(%{podcast_id: podcast.id})

    conn =
      assign(conn, :current_user, user)
      |> Plug.Conn.put_req_header("referer", "/episodes/" <> Integer.to_string(episode.id))
      |> post(
        recommendation_frontend_path(conn, :create, %{
          recommendation: %{episode_id: episode.id, comment: "recommendation comment"}
        })
      )

    assert redirected_to(conn) == episode_frontend_path(conn, :show, episode)

    assert Repo.get_by(Recommendation, %{
             episode_id: episode.id,
             user_id: user.id,
             comment: "recommendation comment"
           })

    assert Repo.get_by(Message, %{
             topic: "podcasts",
             subtopic: Integer.to_string(podcast.id),
             event: "recommend",
             type: "success",
             creator_id: user.id
           })
  end

  # FIXME
  @tag :currently_broken
  test "can create an chapter recommendation, a message and redirects back", %{conn: conn} do
    user = insert_user()
    podcast = insert_podcast()
    episode = insert_episode(%{podcast_id: podcast.id})
    chapter = insert_chapter(%{episode_id: episode.id})

    conn =
      assign(conn, :current_user, user)
      |> Plug.Conn.put_req_header("referer", "/episodes/" <> Integer.to_string(episode.id))
      |> post(
        recommendation_frontend_path(conn, :create, %{
          recommendation: %{chapter_id: chapter.id, comment: "recommendation comment"}
        })
      )

    assert redirected_to(conn) == episode_frontend_path(conn, :show, episode)

    assert Repo.get_by(Recommendation, %{
             chapter_id: chapter.id,
             user_id: user.id,
             comment: "recommendation comment"
           })

    assert Repo.get_by(Message, %{
             topic: "podcasts",
             subtopic: Integer.to_string(podcast.id),
             event: "recommend",
             type: "success",
             creator_id: user.id
           })
  end
end
