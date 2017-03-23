defmodule Pan.DelegationTest do
  use Pan.ModelCase

  alias Pan.Delegation

  @invalid_attrs %{}

  test "changeset with valid attributes" do
    persona = insert_persona()
    delegate = insert_persona(%{pid:  "delegate pid",
                                name: "delegate name",
                                uri:  "delegate uri"})

    changeset = Delegation.changeset(%Delegation{persona_id: persona.id,
                                                 delegate_id: delegate.id})
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Delegation.changeset(%Delegation{}, @invalid_attrs)
    refute changeset.valid?
  end
end
