defmodule Pan.PersonaTest do
  use Pan.ModelCase

  alias PanWeb.Persona

  @valid_attrs %{
    description: "Persona description",
    email: "jimmy.persona@panoptikum.io",
    image_title: "Jimmy Persona portrait",
    image_url: "https://panoptikum.io/persona/image",
    name: "Jimmy Persona",
    pid: "1e75ff9d-0582-5e1f-8611-3165fbd9f4f9 ",
    uri: "https://panoptikum.io/persona/uri"
  }
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
