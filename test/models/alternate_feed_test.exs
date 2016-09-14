defmodule Pan.AlternateFeedTest do
  use Pan.ModelCase

  alias Pan.AlternateFeed

  @valid_attrs %{title: "some content", url: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = AlternateFeed.changeset(%AlternateFeed{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = AlternateFeed.changeset(%AlternateFeed{}, @invalid_attrs)
    refute changeset.valid?
  end
end
