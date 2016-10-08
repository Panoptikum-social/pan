defmodule Pan.Repo.Migrations.CreateLanguage do
  use Ecto.Migration

  def change do
    create table(:languages) do
      add :shortcode, :string
      add :name, :string

      timestamps
    end
    create unique_index(:languages, [:shortcode])

  end
end
