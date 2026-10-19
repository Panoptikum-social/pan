defmodule Pan.Parser.CategoryTest do
  use Pan.DataCase

  alias Pan.Parser.Category, as: ParserCategory
  alias PanWeb.Category

  defp unique_title(title), do: "#{title} #{System.unique_integer([:positive])}"

  test "a title differing in case and surrounding spaces finds the existing category" do
    title = unique_title("Sports & Recreation")
    {:ok, existing} = Repo.insert(%Category{title: title})

    assert {:ok, %{id: id}} = ParserCategory.get_or_insert("  #{String.downcase(title)} ", nil)
    assert id == existing.id
  end

  test "subcategories match ignoring case as well, below the matching parent" do
    parent_title = unique_title("Technology")
    {:ok, parent} = Repo.insert(%Category{title: parent_title})
    {:ok, child} = Repo.insert(%Category{title: "Podcasting", parent_id: parent.id})

    assert {:ok, %{id: id}} =
             ParserCategory.get_or_insert("podcasting", String.upcase(parent_title))

    assert id == child.id
  end

  test "where case variants exist side by side, the exact title wins" do
    title = unique_title("Education")
    {:ok, _lower} = Repo.insert(%Category{title: String.downcase(title)})
    {:ok, exact} = Repo.insert(%Category{title: title})

    assert {:ok, %{id: id}} = ParserCategory.get_or_insert(title, nil)
    assert id == exact.id
  end

  test "a new category gets the trimmed title" do
    title = unique_title("Brand New")

    assert {:ok, category} = ParserCategory.get_or_insert(" #{title}  ", nil)
    assert category.title == title
  end
end
