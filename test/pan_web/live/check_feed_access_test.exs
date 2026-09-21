defmodule PanWeb.Live.CheckFeedAccessTest do
  use PanWeb.ConnCase

  import Phoenix.LiveViewTest
  import PanWeb.Router.Helpers

  alias Pan.Repo
  alias PanWeb.{Podcast, User}

  defp insert_user(attrs \\ []) do
    n = System.unique_integer([:positive])

    %User{name: "Test", username: "feedcheck_#{n}", email: "feedcheck_#{n}@example.com"}
    |> struct(attrs)
    |> Repo.insert!()
  end

  defp insert_podcast(attrs \\ []) do
    n = System.unique_integer([:positive])

    %Podcast{title: "Feed check podcast #{n}", description: "d"}
    |> struct(attrs)
    |> Repo.insert!()
  end

  defp logged_in(conn, user), do: init_test_session(conn, %{"user_id" => user.id})

  test "manageable_by? is true for the owner, admins and moderators only" do
    owner = insert_user()
    podcast = insert_podcast(user_id: owner.id)

    assert Podcast.manageable_by?(podcast, owner.id)
    assert Podcast.manageable_by?(podcast, insert_user(admin: true).id)
    assert Podcast.manageable_by?(podcast, insert_user(moderator: true).id)
    refute Podcast.manageable_by?(podcast, insert_user().id)
    refute Podcast.manageable_by?(podcast, nil)
  end

  test "a user who does not manage the podcast is sent back to the podcast page", %{conn: conn} do
    podcast = insert_podcast(user_id: insert_user().id)
    path = podcast_frontend_path(@endpoint, :check_feed, podcast)

    assert {:error, {:live_redirect, %{to: to}}} = live(logged_in(conn, insert_user()), path)
    assert to == podcast_frontend_path(@endpoint, :show, podcast)
  end

  test "the owner, an admin and a moderator get the page", %{conn: conn} do
    owner = insert_user()
    podcast = insert_podcast(user_id: owner.id)
    path = podcast_frontend_path(@endpoint, :check_feed, podcast)

    for user <- [owner, insert_user(admin: true), insert_user(moderator: true)] do
      assert html_response(get(logged_in(conn, user), path), 200) =~ "Feed check"
    end
  end
end
