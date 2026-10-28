defmodule PanWeb.Live.ModerationApiErrorsTest do
  use PanWeb.ConnCase

  import Phoenix.LiveViewTest
  import PanWeb.Router.Helpers

  alias Pan.Repo
  alias PanWeb.{ApiRequestError, Category, Community, Feed, Moderation, Podcast, User}

  defp insert_moderator do
    n = System.unique_integer([:positive])

    Repo.insert!(%User{
      name: "Test",
      username: "apierrors_#{n}",
      email: "apierrors_#{n}@example.com",
      moderator: true
    })
  end

  defp logged_in(conn, user), do: init_test_session(conn, %{"user_id" => user.id})

  setup do
    category = Repo.insert!(%Category{title: "API errors category #{System.unique_integer()}"})
    community = Repo.insert!(%Community{title: "API errors community", category_id: category.id})

    podcast =
      Repo.insert!(%Podcast{
        title: "Broken Show",
        update_intervall: 10,
        next_update: ~N[2030-01-01 00:00:00]
      })

    feed =
      Repo.insert!(%Feed{podcast_id: podcast.id, self_link_url: "https://broken.example.com"})

    Repo.insert_all("categories_podcasts", [%{category_id: category.id, podcast_id: podcast.id}])

    ApiRequestError.record(
      podcast.id,
      "trigger_episode_update",
      504,
      "Feed download failed",
      "503"
    )

    %{category: category, community: community, podcast: podcast, feed: feed}
  end

  test "moderators of the community see the errors with a link to fix the feed", %{
    conn: conn,
    category: category,
    community: community,
    feed: feed
  } do
    moderator = insert_moderator()
    Repo.insert!(%Moderation{user_id: moderator.id, community_id: community.id})

    {:ok, _view, html} =
      live(logged_in(conn, moderator), moderation_frontend_path(@endpoint, :api_errors, category))

    assert html =~ "Broken Show"
    assert html =~ "Feed download failed"
    assert html =~ moderation_frontend_path(@endpoint, :edit_feed, category.id, feed.id)
  end

  test "other moderators don't", %{conn: conn, category: category} do
    {:ok, _view, html} =
      live(
        logged_in(conn, insert_moderator()),
        moderation_frontend_path(@endpoint, :api_errors, category)
      )

    assert html =~ "This is not one of your moderations"
    refute html =~ "Broken Show"
  end

  test "remove from community keeps the podcast", %{
    conn: conn,
    category: category,
    community: community,
    podcast: podcast
  } do
    moderator = insert_moderator()
    Repo.insert!(%Moderation{user_id: moderator.id, community_id: community.id})

    {:ok, view, _html} =
      live(logged_in(conn, moderator), moderation_frontend_path(@endpoint, :api_errors, category))

    html = view |> element("button", "Remove from community") |> render_click()

    assert html =~ "removed from"
    refute html =~ "Broken Show"
    assert Repo.get(Podcast, podcast.id)
    assert Podcast.ids_by_category_id(category.id) == []
  end
end
