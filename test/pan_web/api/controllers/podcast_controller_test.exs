defmodule PanWeb.Api.PodcastControllerTest do
  use PanWeb.ConnCase

  import Ecto.Query, only: [from: 2]
  import Pan.Parser.MyDateTime, only: [now: 0, time_shift: 2]

  alias Pan.Repo
  alias PanWeb.{ApiRequestError, Category, FormerPodcast, Podcast, User}

  defp insert_user(_context) do
    user =
      %User{
        name: "Test User",
        username: "test_user_#{System.unique_integer([:positive])}",
        email: "test_user_#{System.unique_integer([:positive])}@example.com",
        email_verified: true
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
    test "returns 429 when the podcast was manually updated less than 5 minutes ago", %{
      conn: conn,
      token: token
    } do
      podcast = insert_podcast(%{manually_updated_at: time_shift(now(), minutes: -2)})

      error =
        authenticated_conn(conn, token)
        |> get(Routes.api_podcast_path(conn, :trigger_update, podcast.id))
        |> first_error(429)

      assert error["title"] == "Too many requests"
      assert error["detail"] =~ ~r/available in 1[78]\d seconds\.$/
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
    test "returns 429 when the podcast was manually updated less than 5 minutes ago", %{
      conn: conn,
      token: token
    } do
      podcast = insert_podcast(%{manually_updated_at: time_shift(now(), minutes: -2)})

      error =
        authenticated_conn(conn, token)
        |> get(Routes.api_podcast_path(conn, :trigger_episode_update, podcast.id))
        |> first_error(429)

      assert error["title"] == "Too many requests"
      assert error["detail"] =~ ~r/available in 1[78]\d seconds\.$/
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

  describe "podcasts that no longer exist" do
    test "show returns a JSON 404 and records it", %{conn: conn} do
      error =
        conn
        |> put_req_header("accept", "application/vnd.api+json")
        |> get(Routes.api_podcast_path(conn, :show, 999_999_999))
        |> first_error(404)

      assert error["detail"] == "Podcast with Panoptikum ID 999999999 no longer exists."

      assert [%{podcast_id: 999_999_999, endpoint: "show", status: 404}] =
               Repo.all(ApiRequestError)
    end

    test "trigger_episode_update returns a JSON 404 instead of the HTML page", %{
      conn: conn,
      token: token
    } do
      error =
        authenticated_conn(conn, token)
        |> get(Routes.api_podcast_path(conn, :trigger_episode_update, 999_999_999))
        |> first_error(404)

      assert error["detail"] == "Podcast with Panoptikum ID 999999999 no longer exists."
      assert [%{endpoint: "trigger_episode_update"}] = Repo.all(ApiRequestError)
    end
  end

  describe "former podcasts" do
    test "a merged id names the new id in detail and meta", %{conn: conn} do
      Repo.insert!(%FormerPodcast{id: 999_999_998, title: "Old Show", new_id: 42})

      error =
        conn
        |> put_req_header("accept", "application/vnd.api+json")
        |> get(Routes.api_podcast_path(conn, :show, 999_999_998))
        |> first_error(404)

      assert error["detail"] ==
               "Podcast with Panoptikum ID 999999998 (Old Show) was merged into the podcast " <>
                 "with Panoptikum ID 42, please use that ID."

      assert error["meta"] == %{"new_id" => 42}
    end

    test "a deleted id says so", %{conn: conn, token: token} do
      Repo.insert!(%FormerPodcast{id: 999_999_997, title: "Gone Show"})

      error =
        authenticated_conn(conn, token)
        |> get(Routes.api_podcast_path(conn, :trigger_episode_update, 999_999_997))
        |> first_error(404)

      assert error["detail"] == "Podcast with Panoptikum ID 999999997 (Gone Show) was deleted."
      refute error["meta"]
    end
  end

  describe "error recording" do
    test "records the error title and detail of a failed request", %{conn: conn, token: token} do
      podcast = insert_podcast(%{manually_updated_at: time_shift(now(), minutes: -2)})

      authenticated_conn(conn, token)
      |> get(Routes.api_podcast_path(conn, :trigger_episode_update, podcast.id))
      |> first_error(429)

      assert [%{podcast_id: id, status: 429, title: "Too many requests", detail: detail}] =
               Repo.all(ApiRequestError)

      assert id == podcast.id
      assert detail =~ "seconds."
    end

    test "does not record trigger_update, which wisspod.de doesn't poll", %{
      conn: conn,
      token: token
    } do
      podcast = insert_podcast(%{manually_updated_at: time_shift(now(), minutes: -2)})

      authenticated_conn(conn, token)
      |> get(Routes.api_podcast_path(conn, :trigger_update, podcast.id))
      |> first_error(429)

      assert Repo.all(ApiRequestError) == []
    end
  end

  describe "ApiRequestError.last_day_by_podcast/1" do
    test "groups the community's and deleted podcasts' errors, skips others and old ones" do
      category = Repo.insert!(%Category{title: "Community #{System.unique_integer([:positive])}"})
      own = insert_podcast(%{})
      other = insert_podcast(%{})
      Repo.insert_all("categories_podcasts", [%{category_id: category.id, podcast_id: own.id}])

      ApiRequestError.record(own.id, "show", 504, "Feed download failed", "403: forbidden")
      ApiRequestError.record(own.id, "trigger_episode_update", 504, "Feed download failed", "503")
      ApiRequestError.record(other.id, "show", 504, "Feed download failed", "500")
      ApiRequestError.record(999_999_999, "show", 404, "Not found", "gone")

      old = ApiRequestError.record(own.id, "show", 504, "Feed download failed", "old")

      Repo.update_all(from(e in ApiRequestError, where: e.id == ^old.id),
        set: [inserted_at: time_shift(now(), hours: -25)]
      )

      assert [own_entry, deleted] =
               ApiRequestError.last_day_by_podcast(category.id) |> Enum.sort_by(& &1.podcast_id)

      assert own_entry.podcast_id == own.id
      assert own_entry.podcast_title == own.title
      assert own_entry.count == 2
      assert own_entry.latest.detail == "503"
      assert own_entry.endpoints == ["trigger_episode_update", "show"]

      assert deleted.podcast_id == 999_999_999
      assert deleted.podcast_title == nil
    end
  end
end
