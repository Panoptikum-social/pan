defmodule Pan.AlternateFeedTest do
  use Pan.ModelCase

  alias PanWeb.AlternateFeed

  @valid_attrs %{title: "Alternate feed title", url: "http://panoptikum.io/alternate_feed"}
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
