defmodule Pan.OpmlTest do
  use Pan.ModelCase

  alias Pan.Opml

  @valid_attrs %{content_type: "text/x-opml+xml",
                 filename: "podcasts.opml",
                 path: "/var/phoenix/pan-uploads/opml/6/podcasts.opml"}
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
