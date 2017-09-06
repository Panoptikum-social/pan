defmodule Pan.LanguageTest do
  use Pan.ModelCase

  alias PanWeb.Language

  @valid_attrs %{name: "de-DE",
                 shortcode: "DE"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Language.changeset(%Language{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Language.changeset(%Language{}, @invalid_attrs)
    refute changeset.valid?
  end
end
