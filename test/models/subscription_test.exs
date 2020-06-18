defmodule Pan.SubscriptionTest do
  use Pan.ModelCase

  alias PanWeb.Subscription

  describe "changeset" do
    test "is valid with valid attributes" do
      podcast = insert_podcast()
      user = insert_user()

      changeset =
        Subscription.changeset(%Subscription{}, %{user_id: user.id, podcast_id: podcast.id})

      assert changeset.valid?
    end

    test "is invalid with empty attributes" do
      changeset = Subscription.changeset(%Subscription{}, %{})
      refute changeset.valid?
    end
  end

  describe "get_or_insert" do
    test "inserts new subscription" do
      podcast = insert_podcast()
      user = insert_user()

      assert {:ok, subscription} = Subscription.get_or_insert(user.id, podcast.id)
      id = subscription.id
      assert %Subscription{id: ^id} = Repo.get!(Subscription, id)
    end

    test "gets existing subscription" do
      podcast = insert_podcast()
      user = insert_user()
      {:ok, existing} = Subscription.get_or_insert(user.id, podcast.id)

      assert {:ok, subscription} = Subscription.get_or_insert(user.id, podcast.id)
      assert existing.id == subscription.id
    end
  end
end
