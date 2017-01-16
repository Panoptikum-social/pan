defmodule Pan.GigTest do
  use Pan.ModelCase

  alias Pan.Gig

  @valid_attrs %{comment: "some content", from_in_s: 42, publishing_date: %{day: 17, hour: 14, min: 0, month: 4, sec: 0, year: 2010}, role: "some content", until_in_s: 42}
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
