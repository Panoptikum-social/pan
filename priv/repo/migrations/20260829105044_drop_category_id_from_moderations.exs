defmodule Pan.Repo.Migrations.DropCategoryIdFromModerations do
  use Ecto.Migration

  # category_id on moderations has been fully superseded by community_id (a
  # Community is unique per category_id, so moderation.community.category_id
  # was always the same value) and hasn't been read or written by any app
  # code since PanWeb.Moderation stopped declaring it as a schema field.
  # Dropping it loses no information. down/0 restores the column and
  # repopulates it from community_id, so this stays fully reversible (the
  # earlier seed/backfill migration's down/0 still filters moderations by
  # category_id on rollback).
  def up do
    alter table(:moderations) do
      remove(:category_id)
    end
  end

  def down do
    alter table(:moderations) do
      add(:category_id, references(:categories, on_delete: :nothing))
    end

    execute("""
    UPDATE moderations
    SET category_id = (SELECT category_id FROM communities WHERE id = moderations.community_id)
    """)
  end
end
