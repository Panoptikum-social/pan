defmodule PanWeb.CategoryMapping do
  @moduledoc """
  A category name as feeds use it (with the parent name for a subcategory)
  and the existing category the parser files such podcasts under instead of
  creating the name again (Pan.Parser.Category). Names match ignoring case
  and surrounding spaces. A merge on /admin/categories/merge records one for
  the merged category's names.
  """
  use PanWeb, :model
  alias Pan.Repo
  alias PanWeb.{Category, CategoryMapping}

  schema "category_mappings" do
    field(:parent_title, :string)
    field(:title, :string)

    belongs_to(:category, Category)

    timestamps()
  end

  @doc "The category the names `parent_title` › `title` are mapped to, or nil."
  def target(parent_title, title) do
    from(m in CategoryMapping,
      join: c in assoc(m, :category),
      where:
        fragment("lower(coalesce(?, ''))", m.parent_title) == ^normalize(parent_title) and
          fragment("lower(?)", m.title) == ^normalize(title),
      select: c
    )
    |> Repo.one()
  end

  defp normalize(nil), do: ""
  defp normalize(title), do: title |> String.trim() |> String.downcase()

  @doc """
  Maps the names `parent_title` › `title` to category `category_id`,
  replacing an existing mapping of the same names.
  """
  def put(parent_title, title, category_id) do
    Repo.insert!(
      %CategoryMapping{
        parent_title: parent_title && String.trim(parent_title),
        title: String.trim(title),
        category_id: category_id
      },
      on_conflict: [set: [category_id: category_id, updated_at: now()]],
      conflict_target: {:unsafe_fragment, ~s|(lower(coalesce(parent_title, '')), lower(title))|}
    )
  end

  defp now, do: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

  @doc "Mappings pointing at `from_id` point at `to_id` afterwards (a merge deletes `from_id`)."
  def repoint(from_id, to_id) do
    from(m in CategoryMapping, where: m.category_id == ^from_id)
    |> Repo.update_all(set: [category_id: to_id])
  end

  @doc "All mappings with their target category and its parent, sorted by names."
  def list do
    from(m in CategoryMapping,
      order_by: [
        asc: fragment("lower(coalesce(?, ''))", m.parent_title),
        asc: fragment("lower(?)", m.title)
      ],
      preload: [category: :parent]
    )
    |> Repo.all()
  end

  def delete(id), do: Repo.get!(CategoryMapping, id) |> Repo.delete!()
end
