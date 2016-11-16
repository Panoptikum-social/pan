defmodule Pan.FollowTest do
  use Pan.ModelCase

  alias Pan.Follow

  @valid_attrs %{}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Follow.changeset(%Follow{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Follow.changeset(%Follow{}, @invalid_attrs)
    refute changeset.valid?
  end
end
