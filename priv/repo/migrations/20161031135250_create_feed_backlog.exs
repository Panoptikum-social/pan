defmodule Pan.Repo.Migrations.CreateFeedBacklog do
  use Ecto.Migration

  def change do
    create table(:backlog_feeds) do
      add(:url, :string)
      add(:feed_generator, :string)
      add(:in_progress, :boolean, default: false, null: false)
      add(:user_id, references(:users, on_delete: :nothing))

      timestamps()
    end

    create(index(:backlog_feeds, [:user_id]))
  end
end
