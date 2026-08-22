defmodule Pan.Repo.Migrations.AddHashToFeeds do
  use Ecto.Migration

  def change do
    alter table(:feeds) do
      add(:hash, :string)
    end
  end
end
