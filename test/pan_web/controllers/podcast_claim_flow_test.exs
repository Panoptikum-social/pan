defmodule PanWeb.PodcastClaimFlowTest do
  use PanWeb.ConnCase

  import Swoosh.TestAssertions
  import PanWeb.Router.Helpers

  alias Pan.Repo
  alias PanWeb.{Engagement, Journal, Persona, Podcast, User}

  defp insert_user(attrs \\ []) do
    n = System.unique_integer([:positive])

    %User{name: "Claimer", username: "claimflow_#{n}", email: "claimflow_#{n}@example.com"}
    |> struct(attrs)
    |> Repo.insert!()
  end

  defp insert_podcast(owner_email, attrs \\ []) do
    n = System.unique_integer([:positive])

    podcast =
      %Podcast{title: "Claim flow #{n}", description: "d"} |> struct(attrs) |> Repo.insert!()

    if owner_email do
      persona = Repo.insert!(%Persona{pid: "claimflow-#{n}", name: "Owner", email: owner_email})
      Repo.insert!(%Engagement{podcast_id: podcast.id, persona_id: persona.id, role: "owner"})
    end

    podcast
  end

  defp logged_in(conn, user), do: init_test_session(conn, %{"user_id" => user.id})

  test "a verified user triggers a confirmation mail to the owner address", %{conn: conn} do
    user = insert_user(email_verified: true)
    podcast = insert_podcast(" Owner@Feed.org ")

    conn = post(logged_in(conn, user), podcast_frontend_path(conn, :claim, podcast))

    assert redirected_to(conn) == podcast_frontend_path(conn, :show, podcast)

    assert_email_sent(
      to: "owner@feed.org",
      subject: "Panoptikum - Podcast ownership confirmation request"
    )

    assert Repo.get!(Podcast, podcast.id).user_id == nil
  end

  test "an unverified user, an assigned podcast and a missing owner address send nothing", %{
    conn: conn
  } do
    unverified = insert_user(email_verified: false)
    verified = insert_user(email_verified: true)

    post(
      logged_in(conn, unverified),
      podcast_frontend_path(conn, :claim, insert_podcast("a@b.org"))
    )

    post(
      logged_in(conn, verified),
      podcast_frontend_path(conn, :claim, insert_podcast("a@b.org", user_id: unverified.id))
    )

    post(logged_in(conn, verified), podcast_frontend_path(conn, :claim, insert_podcast(nil)))

    assert_no_email_sent()
  end

  test "the mailed link asks for approval and approving assigns the podcast once", %{conn: conn} do
    user = insert_user(email_verified: true)
    podcast = insert_podcast("owner@feed.org")
    token = Podcast.claim_token(podcast.id, user.id)

    page = get(conn, podcast_frontend_path(conn, :confirm_ownership, podcast, token: token))
    assert html_response(page, 200) =~ "Approve"
    assert Repo.get!(Podcast, podcast.id).user_id == nil

    approved =
      post(conn, podcast_frontend_path(conn, :grant_ownership, podcast), %{"token" => token})

    assert html_response(approved, 200) =~ "Ownership confirmed"
    assert Repo.get!(Podcast, podcast.id).user_id == user.id
    assert Repo.get_by(Journal, method: "claim_by_confirmation", after: to_string(user.id))

    again =
      post(conn, podcast_frontend_path(conn, :grant_ownership, podcast), %{"token" => token})

    assert html_response(again, 200) =~ "managed by someone already"
  end

  test "invalid tokens and tokens for another podcast are refused", %{conn: conn} do
    user = insert_user(email_verified: true)
    podcast = insert_podcast("owner@feed.org")
    other = insert_podcast("other@feed.org")

    for token <- ["garbage", Podcast.claim_token(other.id, user.id)] do
      response =
        post(conn, podcast_frontend_path(conn, :grant_ownership, podcast), %{"token" => token})

      assert html_response(response, 200) =~ "The link is invalid."
    end

    assert Repo.get!(Podcast, podcast.id).user_id == nil
  end
end
