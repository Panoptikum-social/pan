defmodule Pan.DelegationTest do
  use Pan.ModelCase

  alias Pan.Delegation

  @valid_attrs %{}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Delegation.changeset(%Delegation{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Delegation.changeset(%Delegation{}, @invalid_attrs)
    refute changeset.valid?
  end
end
