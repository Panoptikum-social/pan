defmodule Pan.Repo.Migrations.CreateCategoryMappings do
  use Ecto.Migration

  # Category names from feeds (with the parent name for subcategories) that
  # the parser files under an existing category instead of creating them,
  # see PanWeb.CategoryMapping. Filled by merges on /admin/categories/merge.
  def change do
    create table(:category_mappings) do
      add(:parent_title, :string)
      add(:title, :string, null: false)
      add(:category_id, references(:categories, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:category_mappings, [:category_id]))

    create(
      unique_index(:category_mappings, ["lower(coalesce(parent_title, ''))", "lower(title)"],
        name: :category_mappings_names_index
      )
    )
  end
end
