defmodule Pan.FollowTest do
  use Pan.ModelCase

  alias Pan.Follow

  @invalid_attrs %{}

  test "changeset with valid attributes" do
    follower = insert_user()
    podcast = insert_podcast()

    changeset = Follow.changeset(%Follow{follower_id: follower.id, podcast_id: podcast.id})
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Follow.changeset(%Follow{}, @invalid_attrs)
    refute changeset.valid?
  end
end
