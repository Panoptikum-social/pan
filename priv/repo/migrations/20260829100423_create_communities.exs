defmodule Pan.Repo.Migrations.CreateCommunities do
  use Ecto.Migration

  def change do
    create table(:communities) do
      add(:title, :string, null: false)
      add(:website, :string)
      add(:description, :text)
      add(:fediverse_address, :string)
      add(:category_id, references(:categories, on_delete: :nothing), null: false)

      timestamps()
    end

    # exactly one Community per community-category
    create(unique_index(:communities, [:category_id]))
  end
end
