defmodule Pan.EnclosureTest do
  use Pan.ModelCase

  alias PanWeb.Enclosure

  @valid_attrs %{
    guid: "https://panoptikum.io/path/enclosure.mp3",
    length: "123456789",
    type: "audio/mp4",
    url: "https://panoptikum.io/path/enclosure.mp3"
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Enclosure.changeset(%Enclosure{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Enclosure.changeset(%Enclosure{}, @invalid_attrs)
    refute changeset.valid?
  end
end
