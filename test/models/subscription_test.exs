defmodule Pan.SubscriptionTest do
  use Pan.ModelCase

  alias Pan.Subscription

  @valid_attrs %{}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    podcast = insert_podcast()
    user = insert_user()
    changeset = Subscription.changeset(%Subscription{},
                                       Map.merge(@valid_attrs, %{user_id: user.id,
                                                                 podcast_id: podcast.id}))
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Subscription.changeset(%Subscription{}, @invalid_attrs)
    refute changeset.valid?
  end
end
