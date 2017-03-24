defmodule Pan.MessageTest do
  use Pan.ModelCase

  alias Pan.Message

  @valid_attrs %{content: "Message content",
                 event: "like",
                 subtopic: "42",
                 topic: "users",
                 type: "success"}
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
