defmodule Pan.OpmlTest do
  use Pan.ModelCase

  alias Pan.Opml

  @valid_attrs %{content_type: "some content", filename: "some content", path: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Opml.changeset(%Opml{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Opml.changeset(%Opml{}, @invalid_attrs)
    refute changeset.valid?
  end
end
