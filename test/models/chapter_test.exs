defmodule Pan.ChapterTest do
  use Pan.ModelCase

  alias Pan.Chapter

  @valid_attrs %{start: "some content", title: "some content"}
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
