defmodule PanWeb.CategoryMergeTest do
  use Pan.DataCase

  alias Pan.Repo
  alias PanWeb.{Category, Community}

  defp insert_category(title), do: Repo.insert!(%Category{title: title})

  defp insert_community(category) do
    Repo.insert!(%Community{
      title: "Community of #{category.title}",
      slug: "community-#{category.id}",
      category_id: category.id
    })
  end

  test "the community of the merged category moves to the target category" do
    from = insert_category("Merge from")
    to = insert_category("Merge into")
    community = insert_community(from)

    assert Category.merge(from.id, to.id) == :ok

    refute Repo.get(Category, from.id)
    assert Repo.get!(Community, community.id).category_id == to.id

    # the re-flagging for search, see Search.Category.reset_podcasts/1
    Pan.Search.ReflagQueue.flush()
  end

  test "refuses to merge two categories that both have a community" do
    from = insert_category("Merge from")
    to = insert_category("Merge into")
    insert_community(from)
    insert_community(to)

    assert {:error, message} = Category.merge(from.id, to.id)
    assert message =~ "Both categories have a community"
    assert Repo.get(Category, from.id)
  end

  test "refuses to merge a category into itself" do
    category = insert_category("Self merge")

    assert {:error, _message} = Category.merge(category.id, category.id)
    assert Repo.get(Category, category.id)
  end

  describe "mappings" do
    alias PanWeb.CategoryMapping

    test "merging maps the merged category's names to the target" do
      parent = insert_category("Old parent #{System.unique_integer([:positive])}")
      from = Repo.insert!(%Category{title: "Outdoor", parent_id: parent.id})
      to = insert_category("Wilderness #{System.unique_integer([:positive])}")

      assert Category.merge(from.id, to.id) == :ok
      assert CategoryMapping.target(parent.title, "outdoor").id == to.id
      Pan.Search.ReflagQueue.flush()
    end

    test "mappings to the merged category move to the target" do
      from = insert_category("Middle #{System.unique_integer([:positive])}")
      to = insert_category("Final #{System.unique_integer([:positive])}")
      CategoryMapping.put(nil, "Earlier name #{from.id}", from.id)

      assert Category.merge(from.id, to.id) == :ok
      assert CategoryMapping.target(nil, "Earlier name #{from.id}").id == to.id
      assert CategoryMapping.target(nil, from.title).id == to.id
      Pan.Search.ReflagQueue.flush()
    end

    test "merging a namesake into the target records no mapping" do
      title = "Namesake #{System.unique_integer([:positive])}"
      from = insert_category(title)
      to = insert_category(title)

      assert Category.merge(from.id, to.id) == :ok
      refute CategoryMapping.target(nil, title)
      Pan.Search.ReflagQueue.flush()
    end
  end
end
