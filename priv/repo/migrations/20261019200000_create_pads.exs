defmodule Pan.Repo.Migrations.CreatePads do
  use Ecto.Migration

  # Community pads: markdown edited together by the followers of a community.
  # The title is unique within its community, the slug made from it is the
  # pad's address. Unlike most older tables, deleting a community deletes its
  # pads and their snapshots in the database itself, so the cascade also
  # reaches the snapshots (Ecto's on_delete only goes one level deep).
  def change do
    create table(:pads) do
      add(:community_id, references(:communities, on_delete: :delete_all), null: false)
      add(:title, :string, null: false)
      add(:slug, :string, null: false)
      add(:read_only, :boolean, default: false, null: false)
      # Yjs document for editing, NULL until the first edit
      add(:yjs_state, :binary)
      # markdown copy for display and search
      add(:markdown, :text, default: "", null: false)

      timestamps()
    end

    create(unique_index(:pads, [:community_id, :slug]))

    create table(:pad_snapshots) do
      add(:pad_id, references(:pads, on_delete: :delete_all), null: false)
      add(:markdown, :text, null: false)
      # only set by "Save version"
      add(:note, :string)
      # who pressed "Save version"; NULL for automatic snapshots and once the
      # user is deleted
      add(:user_id, references(:users, on_delete: :nilify_all))

      timestamps(updated_at: false)
    end

    create(index(:pad_snapshots, [:pad_id]))
  end
end
