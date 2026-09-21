defmodule PanWeb.PodcastClaimTest do
  use Pan.DataCase

  alias Pan.Repo
  alias PanWeb.{Engagement, Journal, Persona, Podcast, User}

  defp insert_user(attrs) do
    n = System.unique_integer([:positive])

    %User{name: "Test", username: "claim_#{n}", email: "claim_#{n}@example.com"}
    |> struct(attrs)
    |> Repo.insert!()
  end

  defp insert_podcast_with_owner(owner_email, attrs \\ []) do
    n = System.unique_integer([:positive])

    podcast =
      %Podcast{title: "Claim podcast #{n}", description: "d"}
      |> struct(attrs)
      |> Repo.insert!()

    persona = Repo.insert!(%Persona{pid: "claim-#{n}", name: "Owner #{n}", email: owner_email})
    Repo.insert!(%Engagement{podcast_id: podcast.id, persona_id: persona.id, role: "owner"})
    podcast
  end

  test "assigns unassigned podcasts whose owner email matches, ignoring case and whitespace" do
    user = insert_user(email: "Owner@Example.com", email_verified: true)
    match = insert_podcast_with_owner("  owner@example.com ")
    other = insert_podcast_with_owner("someone@else.org")

    assert Podcast.claim_by_owner_email(user) == [match.id]
    assert Repo.get(Podcast, match.id).user_id == user.id
    assert Repo.get(Podcast, other.id).user_id == nil
    assert Enum.map(Podcast.owned_by(user.id), & &1.id) == [match.id]

    assert Repo.get_by(Journal, method: "claim_by_owner_email", after: to_string(user.id))
  end

  test "does nothing for an unverified email" do
    user = insert_user(email: "unverified@example.com", email_verified: false)
    podcast = insert_podcast_with_owner("unverified@example.com")

    assert Podcast.claim_by_owner_email(user) == []
    assert Repo.get(Podcast, podcast.id).user_id == nil
  end

  test "never overrides an existing assignment" do
    first = insert_user(email_verified: true)
    second = insert_user(email: "second@example.com", email_verified: true)
    podcast = insert_podcast_with_owner("second@example.com", user_id: first.id)

    assert Podcast.claim_by_owner_email(second) == []
    assert Repo.get(Podcast, podcast.id).user_id == first.id
  end

  test "a podcast with two owner personas is assigned once" do
    user = insert_user(email: "dup@example.com", email_verified: true)
    podcast = insert_podcast_with_owner("dup@example.com")
    persona = Repo.insert!(%Persona{pid: "claim-dup", name: "Dup", email: "dup@example.com"})
    Repo.insert!(%Engagement{podcast_id: podcast.id, persona_id: persona.id, role: "owner"})

    assert Podcast.claim_by_owner_email(user) == [podcast.id]
  end
end
