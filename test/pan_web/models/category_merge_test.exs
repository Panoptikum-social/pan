defmodule PanWeb.CategoryMergeTest do
  use Pan.DataCase

  alias Pan.Repo
  alias PanWeb.{Category, Community}

  defp insert_category(title), do: Repo.insert!(%Category{title: title})

  defp insert_community(category) do
    Repo.insert!(%Community{title: "Community of #{category.title}", category_id: category.id})
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
end
