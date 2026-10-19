defmodule PanWeb.CategoryMoveTest do
  use Pan.DataCase

  alias Pan.Repo
  alias PanWeb.Category

  defp insert_category(title, parent \\ nil),
    do: Repo.insert!(%Category{title: title, parent_id: parent && parent.id})

  test "a category with its subcategories becomes a subcategory of the target" do
    moved = insert_category("Deportes")
    child = insert_category("Fútbol", moved)
    target = insert_category("Sports")

    assert Category.move_into(moved.id, target.id) == :ok

    assert Repo.get!(Category, moved.id).parent_id == target.id
    assert Repo.get!(Category, child.id).parent_id == moved.id
  end

  test "a category can't be moved into itself or its own subcategory" do
    moved = insert_category("Parent")
    child = insert_category("Child", moved)

    assert {:error, _} = Category.move_into(moved.id, moved.id)
    assert {:error, message} = Category.move_into(moved.id, child.id)
    assert message =~ "own subcategories"
  end

  test "a move must not make the tree deeper than three levels" do
    top = insert_category("Top")
    middle = insert_category("Middle", top)
    moved = insert_category("With child")
    insert_category("Its child", moved)

    assert {:error, message} = Category.move_into(moved.id, middle.id)
    assert message =~ "deeper"
    assert Category.move_into(moved.id, top.id) == :ok
  end

  test "a target with a subcategory of the same title asks for a merge instead" do
    target = insert_category("Sports")
    insert_category("Running", target)
    moved = insert_category(" running ")

    assert {:error, message} = Category.move_into(moved.id, target.id)
    assert message =~ "merge instead"
  end

  test "a category already directly below the target is refused" do
    target = insert_category("Sports")
    moved = insert_category("Running", target)

    assert {:error, message} = Category.move_into(moved.id, target.id)
    assert message =~ "already"
  end
end
