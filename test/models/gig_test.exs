defmodule Pan.GigTest do
  use Pan.ModelCase

  alias Pan.Gig

  @valid_attrs %{comment: "Gig comment",
                 from_in_s: 42,
                 publishing_date: "2010-04-17 14:00:00",
                 role: "contributor",
                 until_in_s: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Gig.changeset(%Gig{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Gig.changeset(%Gig{}, @invalid_attrs)
    refute changeset.valid?
  end
end
