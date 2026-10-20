defmodule Pan.AppleCategoriesTest do
  use Pan.DataCase

  alias Pan.{AppleCategories, Repo}
  alias PanWeb.Category

  defp insert_category(title, parent \\ nil, apple \\ false),
    do: Repo.insert!(%Category{title: title, parent_id: parent && parent.id, apple: apple})

  defp apple?(category), do: Repo.get!(Category, category.id).apple

  describe "update_flags/1" do
    test "flags the listed categories the parser would pick, unflags the rest" do
      sports = insert_category("Sports")
      football = insert_category("football ", sports)
      old_sports = insert_category("Sports & Recreation")
      old_football = insert_category("Football", old_sports)
      # a namesake below another parent and a younger top level namesake
      younger_sports = insert_category("sports")
      stale = insert_category("Health", nil, true)

      result = AppleCategories.update_flags([{"Sports", ["Football", "Cricket"]}])

      assert apple?(sports)
      assert apple?(football)
      refute apple?(old_sports)
      refute apple?(old_football)
      refute apple?(younger_sports)
      refute apple?(stale)

      assert %{flagged: 2, unflagged: 1, missing: ["Sports › Cricket"]} = result
      assert result.apple == 2
    end

    test "subcategories of a top level category that isn't here are missing" do
      result = AppleCategories.update_flags([{"Leisure", ["Video Games"]}])
      assert result.missing == ["Leisure", "Leisure › Video Games"]
      assert result.apple == 0
    end
  end

  describe "Apple categories on the merge page" do
    test "can't be deleted, merged away or moved, but merged into" do
      sports = insert_category("Sports", nil, true)
      other = insert_category("Sports & Recreation")
      empty = insert_category("Cricket", sports, true)

      refute MapSet.member?(Category.empty_ids(), empty.id)
      assert {:error, message} = Category.delete_empty(empty.id)
      assert message =~ "Apple categories"
      assert {:error, _} = Category.merge(sports.id, other.id)
      assert {:error, _} = Category.move_into(sports.id, other.id)

      assert Category.merge(other.id, sports.id) == :ok
      refute Repo.get(Category, other.id)
    end
  end
end
