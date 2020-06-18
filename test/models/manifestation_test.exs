defmodule Pan.ManifestationTest do
  use Pan.ModelCase

  alias PanWeb.Manifestation

  @valid_attrs %{}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    user = insert_user()
    persona = insert_persona()

    changeset =
      Manifestation.changeset(
        %Manifestation{},
        Map.merge(@valid_attrs, %{user_id: user.id, persona_id: persona.id})
      )

    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Manifestation.changeset(%Manifestation{}, @invalid_attrs)
    refute changeset.valid?
  end
end
