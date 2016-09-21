defmodule Pan.ContributorTest do
  use Pan.ModelCase

  alias Pan.Contributor

  @valid_attrs %{name: "some content", uri: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Contributor.changeset(%Contributor{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Contributor.changeset(%Contributor{}, @invalid_attrs)
    refute changeset.valid?
  end
end
