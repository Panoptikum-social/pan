defmodule Pan.PersonaTest do
  use Pan.ModelCase

  alias Pan.Persona

  @valid_attrs %{description: "some content", email: "some content", image_title: "some content", image_url: "some content", name: "some content", pid: "some content", uri: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Persona.changeset(%Persona{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Persona.changeset(%Persona{}, @invalid_attrs)
    refute changeset.valid?
  end
end
