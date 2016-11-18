defmodule Pan.SubscriptionTest do
  use Pan.ModelCase

  alias Pan.Subscription

  @valid_attrs %{}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Subscription.changeset(%Subscription{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Subscription.changeset(%Subscription{}, @invalid_attrs)
    refute changeset.valid?
  end
end
