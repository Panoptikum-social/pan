defmodule Pan.Repo.Migrations.AddShareFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :share_subscriptions, :boolean
      add :share_follows, :boolean
    end
  end
end
