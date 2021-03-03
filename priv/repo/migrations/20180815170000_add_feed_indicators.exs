defmodule Pan.Repo.Migrations.AddFeedIndicators do
  use Ecto.Migration

  def change do
    alter table(:feeds) do
      add(:etag, :string)
      add(:last_modified, :naive_datetime)
      add(:trust_last_modified, :boolean, default: false)
    end
  end
end
