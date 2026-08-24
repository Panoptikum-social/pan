defmodule PanWeb.Api.PodcastControllerTest do
  use PanWeb.ConnCase

  import Pan.Parser.MyDateTime, only: [now: 0, time_shift: 2]

  alias Pan.Repo
  alias PanWeb.{Podcast, User}

  defp insert_user(_context) do
    user =
      %User{
        name: "Test User",
        username: "test_user_#{System.unique_integer([:positive])}",
        email: "test_user_#{System.unique_integer([:positive])}@example.com",
        email_confirmed: true
      }
      |> Repo.insert!()

    token = Phoenix.Token.sign(PanWeb.Endpoint, "user", user.id)

    %{user: user, token: token}
  end

  defp insert_podcast(attrs) do
    %Podcast{}
    |> Podcast.changeset(
      Map.merge(
        %{
          title: "Test Podcast #{System.unique_integer([:positive])}",
          update_intervall: 24,
          next_update: now()
        },
        attrs
      )
    )
    |> Repo.insert!()
  end

  defp authenticated_conn(conn, token) do
    conn
    |> put_req_header("accept", "application/vnd.api+json")
    |> put_req_header("authorization", "Bearer #{token}")
  end

  defp first_error(conn, status), do: json_response(conn, status)["errors"] |> List.first()

  setup [:insert_user]

  describe "trigger_update/3" do
    test "returns 429 when the podcast was manually updated less than 30 minutes ago", %{
      conn: conn,
      token: token
    } do
      podcast = insert_podcast(%{manually_updated_at: time_shift(now(), minutes: -5)})

      conn =
        authenticated_conn(conn, token)
        |> get(Routes.api_podcast_path(conn, :trigger_update, podcast.id))

      assert json_response(conn, 429)["errors"] |> List.first() |> Map.get("title") ==
               "Too many requests"
    end

    test "returns 424 with the last error when the podcast is paused", %{
      conn: conn,
      token: token
    } do
      podcast =
        insert_podcast(%{
          update_paused: true,
          last_error_message: "feed returned 500",
          last_error_occured: time_shift(now(), minutes: -10)
        })

      error =
        authenticated_conn(conn, token)
        |> get(Routes.api_podcast_path(conn, :trigger_update, podcast.id))
        |> first_error(424)

      assert error["title"] == "Podcast paused"
      assert error["meta"]["last_error_message"] == "feed returned 500"

      assert error["meta"]["last_error_occured"] ==
               NaiveDateTime.to_iso8601(podcast.last_error_occured)
    end

    test "returns 424 with the last error when the podcast is retired", %{
      conn: conn,
      token: token
    } do
      podcast =
        insert_podcast(%{
          retired: true,
          last_error_message: "feed returned 500",
          last_error_occured: time_shift(now(), minutes: -10)
        })

      error =
        authenticated_conn(conn, token)
        |> get(Routes.api_podcast_path(conn, :trigger_update, podcast.id))
        |> first_error(424)

      assert error["title"] == "Podcast retired"
      assert error["meta"]["last_error_message"] == "feed returned 500"

      assert error["meta"]["last_error_occured"] ==
               NaiveDateTime.to_iso8601(podcast.last_error_occured)
    end
  end

  describe "trigger_episode_update/3" do
    test "returns 429 when the podcast was manually updated less than 30 minutes ago", %{
      conn: conn,
      token: token
    } do
      podcast = insert_podcast(%{manually_updated_at: time_shift(now(), minutes: -5)})

      conn =
        authenticated_conn(conn, token)
        |> get(Routes.api_podcast_path(conn, :trigger_episode_update, podcast.id))

      assert json_response(conn, 429)["errors"] |> List.first() |> Map.get("title") ==
               "Too many requests"
    end

    test "returns 424 with the last error when the podcast is paused", %{
      conn: conn,
      token: token
    } do
      podcast =
        insert_podcast(%{
          update_paused: true,
          last_error_message: "feed returned 500",
          last_error_occured: time_shift(now(), minutes: -10)
        })

      error =
        authenticated_conn(conn, token)
        |> get(Routes.api_podcast_path(conn, :trigger_episode_update, podcast.id))
        |> first_error(424)

      assert error["title"] == "Podcast paused"
      assert error["meta"]["last_error_message"] == "feed returned 500"

      assert error["meta"]["last_error_occured"] ==
               NaiveDateTime.to_iso8601(podcast.last_error_occured)
    end

    test "returns 424 with the last error when the podcast is retired", %{
      conn: conn,
      token: token
    } do
      podcast =
        insert_podcast(%{
          retired: true,
          last_error_message: "feed returned 500",
          last_error_occured: time_shift(now(), minutes: -10)
        })

      error =
        authenticated_conn(conn, token)
        |> get(Routes.api_podcast_path(conn, :trigger_episode_update, podcast.id))
        |> first_error(424)

      assert error["title"] == "Podcast retired"
      assert error["meta"]["last_error_message"] == "feed returned 500"

      assert error["meta"]["last_error_occured"] ==
               NaiveDateTime.to_iso8601(podcast.last_error_occured)
    end
  end
end
