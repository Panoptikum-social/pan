defmodule Pan.ManifestationTest do
  use Pan.ModelCase

  alias Pan.Manifestation

  @valid_attrs %{}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Manifestation.changeset(%Manifestation{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Manifestation.changeset(%Manifestation{}, @invalid_attrs)
    refute changeset.valid?
  end
end
