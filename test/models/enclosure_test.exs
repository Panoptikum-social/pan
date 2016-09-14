defmodule Pan.EnclosureTest do
  use Pan.ModelCase

  alias Pan.Enclosure

  @valid_attrs %{guid: "some content", length: "some content", type: "some content", url: "some content"}
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
