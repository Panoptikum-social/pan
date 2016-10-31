defmodule Pan.FeedBacklogTest do
  use Pan.ModelCase

  alias Pan.FeedBacklog

  @valid_attrs %{feed_generator: "some content", in_progress: true, url: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = FeedBacklog.changeset(%FeedBacklog{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = FeedBacklog.changeset(%FeedBacklog{}, @invalid_attrs)
    refute changeset.valid?
  end
end
