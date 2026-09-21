defmodule Pan.Repo.Migrations.AddLastLoginAndDeletionMarkToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:last_login_at, :naive_datetime)
      add(:marked_for_deletion_at, :naive_datetime)
    end
  end
end
