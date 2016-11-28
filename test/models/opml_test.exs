defmodule Pan.OPMLTest do
  use Pan.ModelCase

  alias Pan.OPML

  @valid_attrs %{content_type: "some content", filename: "some content", path: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = OPML.changeset(%OPML{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = OPML.changeset(%OPML{}, @invalid_attrs)
    refute changeset.valid?
  end
end
