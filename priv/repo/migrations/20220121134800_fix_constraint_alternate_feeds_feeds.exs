defmodule Pan.Repo.Migrations.FixConstraintAlternateFeedsFeeds do
  use Ecto.Migration

  def change do
    alter table(:alternate_feeds) do
      modify(:feed_id, references(:feeds, on_delete: :delete_all),
        from: references(:feeds, on_delete: :nothing))
    end
  end
end
