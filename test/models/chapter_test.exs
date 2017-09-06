defmodule Pan.ChapterTest do
  use Pan.ModelCase

  alias PanWeb.Chapter

  @valid_attrs %{start: "01:02:03.456",
                 title: "Chatter title"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Chapter.changeset(%Chapter{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Chapter.changeset(%Chapter{}, @invalid_attrs)
    refute changeset.valid?
  end
end
