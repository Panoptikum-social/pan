defmodule Pan.Repo.Migrations.CreateSubscription do
  use Ecto.Migration

  def change do
    drop table(:subscriptions)

    create table(:subscriptions) do
      add :user_id, references(:users, on_delete: :nothing)
      add :podcast_id, references(:podcasts, on_delete: :nothing)

      timestamps()
    end
    create index(:subscriptions, [:user_id])
    create index(:subscriptions, [:podcast_id])

  end
end
