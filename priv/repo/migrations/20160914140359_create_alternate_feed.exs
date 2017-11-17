defmodule Pan.Repo.Migrations.CreateAlternateFeed do
  use Ecto.Migration

  def change do
    create table(:alternate_feeds) do
      add :title, :string
      add :url, :string
      add :feed_id, references(:feeds, on_delete: :nothing)

      timestamps()
    end
    create index(:alternate_feeds, [:feed_id])

  end
end
