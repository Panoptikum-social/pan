defmodule Pan.ContributerTest do
  use Pan.ModelCase

  alias Pan.Contributer

  @valid_attrs %{name: "some content", uri: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Contributer.changeset(%Contributer{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Contributer.changeset(%Contributer{}, @invalid_attrs)
    refute changeset.valid?
  end
end
