defmodule Pan.MessageTest do
  use Pan.ModelCase

  alias Pan.Message

  @valid_attrs %{content: "some content", event: "some content", subtopic: "some content", topic: "some content", type: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Message.changeset(%Message{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Message.changeset(%Message{}, @invalid_attrs)
    refute changeset.valid?
  end
end
